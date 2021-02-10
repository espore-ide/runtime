local RollerState = require("state.roller")
local MultiButton = require("drivers.input.multibutton")
local HoldButton = require("drivers.input.holdbutton")
local mbtrigger = require("drivers.output.mbtrigger")
local OnOff = require("drivers.output.onoff")
local portmap = require("portmap.portmap")
local log = require("core.log")
local mqtt = require("mqtt.service")

local App = {}
local count2type = {
    "button_long_press", "button_short_press", "button_double_press",
    "button_triple_press", "button_quadruple_press", "button_quintuple_press"
}
function App:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- config:
-- inputUp: Input to use for receiving the command to go up
-- inputDown: Input to use for receiving the command to go down
-- outputUp: Output to control the shutter to go up
-- outputDown: Output to control the shutter to go down
-- timeUp: Time to have the shutter go fully up. (milliseconds)
-- timeDown: Time to have the shutter go fully down. (milliseconds)
-- bounce: debounce period to configure for input buttons

function stateStr(pos) return pos and tostring(pos) or "UNDEF" end

function App:init(config)
    local outputUpPin = portmap.outputPin(config.outputUp)
    local outputDownPin = portmap.outputPin(config.outputDown)
    local inputUpPin = portmap.inputPin(config.inputUp)
    local inputDownPin = portmap.inputPin(config.inputDown)
    local this = self

    local log = log:new("apps.roller/" .. self.name)
    local outputUp = OnOff:new({pin = outputUpPin})
    local outputDown = OnOff:new({pin = outputDownPin})
    local positionTopic = mqtt:getTopic(config.mqttTopic, 0)
    local stateTopic = mqtt:getTopic(config.mqttTopic .. "/state", 0)

    config.bounce = config.bounce or 50
    config.timeUp = config.timeUp or 10000
    config.timeDown = config.timeDown or 10000
    config.hold = config.hold or false

    local motorState
    local state = RollerState:new({
        timeUp = config.timeUp,
        timeDown = config.timeDown,
        timeSlack = config.timeSlack,
        callback = function(pos, motor, state)
            motorState = motor
            if motor == RollerState.MOTOR_STATUS_UP then
                outputDown:off()
                outputUp:on()
                stateTopic:publish("OPENING")
            elseif motor == RollerState.MOTOR_STATUS_DOWN then
                outputUp:off()
                outputDown:on()
                stateTopic:publish("CLOSING")
            else
                outputDown:off()
                outputUp:off()
                stateTopic:publish(pos == 100 and "OPEN" or pos == 0 and
                                       "CLOSED" or "STOP")
            end
            positionTopic:publish(stateStr(pos), 0, true)
        end
    })
    local makeButtonHandler = function(targetPos)
        local buttonDown = false
        return function(buttonState)
            if buttonState == 0 then -- buttonState 0 means button down
                buttonDown = true
                if motorState == RollerState.MOTOR_STATUS_STOP then
                    state:setpos(targetPos)
                else
                    state:stop()
                end
            else
                if config.hold and buttonDown then state:stop() end
                buttonDown = false
            end
        end
    end

    local inputUp
    local inputDown

    if config.hold then
        inputUp = HoldButton:new({
            pin = inputUpPin,
            bounce = config.bounce,
            callback = makeButtonHandler(100)
        })
        inputDown = HoldButton:new({
            pin = inputDownPin,
            bounce = config.bounce,
            callback = makeButtonHandler(0)
        })
    else
        local makeMultibuttonHandler = function(targetPos)
            local dir = targetPos == 100 and "-up" or "-down"
            local btnHandler = makeButtonHandler(targetPos)
            local trigger = mbtrigger(this.name .. dir, this.description .. dir,
                                      config.mqttTopic .. "/trigger" .. dir)
            return function(count)
                if count == 1 then
                    btnHandler(0) -- simulate press
                    btnHandler(1)
                end
                trigger(count)
            end
        end

        inputUp = MultiButton:new({
            pin = inputUpPin,
            bounce = config.bounce or 50,
            multiClickTimeout = config.multiClickTimeout or 500,
            longPress = config.longPress or 500,
            callback = makeMultibuttonHandler(100)
        })
        inputDown = MultiButton:new({
            pin = inputDownPin,
            bounce = config.bounce or 50,
            multiClickTimeout = config.multiClickTimeout or 500,
            longPress = config.longPress or 500,
            callback = makeMultibuttonHandler(0)
        })

    end

    local setPositionTopic = mqtt:subscribe(config.mqttTopic .. "/set", 0,
                                            function(data)
        local pos = tonumber(data)
        if pos == nil and data == "STOP" then
            state:stop()
        else
            state:setpos(pos)
        end
    end)

    mqtt:runOnConnect(function(reconnect)
        local pos = state:getpos()
        positionTopic:publish(stateStr(pos), 0, true)
        stateTopic:publish(pos == 100 and "OPEN" or pos == 0 and "CLOSED" or
                               "STOP")
        local hass = require("integration.hass")
        hass.publishConfig({
            component = hass.COVER,
            objectId = this.name,
            config = {
                name = this.description,
                set_position_topic = mqtt.base .. config.mqttTopic .. "/set",
                position_topic = mqtt.base .. config.mqttTopic,
                position_open = 100,
                position_closed = 0,
                state_closed = "CLOSED",
                state_open = "OPEN",
                state_closing = "CLOSING",
                state_opening = "OPENING",
                payload_stop = "STOP",
                payload_open = "100",
                payload_close = "0",
                optimistic = false,
                device_class = "shutter",
                command_topic = mqtt.base .. config.mqttTopic .. "/set",
                state_topic = mqtt.base .. config.mqttTopic .. "/state"
            }
        })
    end)

    self.outputUp = outputUp
    self.outputDown = outputDown
    self.inputUp = inputUp
    self.inputDown = inputDown
    self.state = state
end

function App:terminate()
    self.inputUp:destroy()
    self.outputUp:destroy()
    self.inputDown:destroy()
    self.outputDown:destroy()
    self.state:destroy()
end

return App
