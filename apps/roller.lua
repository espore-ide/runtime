local RollerState = require("state.roller")
local PushButton = require("drivers.input.pushbutton")
local OnOff = require("drivers.output.onoff")
local portmap = require("portmap.portmap")
local log = require("core.log")
local mqtt = require("mqtt.service")

local App = {}

function App:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--config:
-- inputUp: Input to use for receiving the command to go up
-- inputDown: Input to use for receiving the command to go down
-- outputUp: Output to control the shutter to go up
-- outputDown: Output to control the shutter to go down
-- timeUp: Time to have the shutter go fully up. (milliseconds)
-- timeDown: Time to have the shutter go fully down. (milliseconds)
-- bounce: debounce period to configure for input buttons

function App:init(config)
    local outputUpPin = portmap.outputPin(config.outputUp)
    local outputDownPin = portmap.outputPin(config.outputDown)
    local inputUpPin = portmap.inputPin(config.inputUp)
    local inputDownPin = portmap.inputPin(config.inputDown)

    local log = log:new("apps.roller/" .. self.name)
    local outputUp = OnOff:new({pin = outputUpPin})
    local outputDown = OnOff:new({pin = outputDownPin})
    local statusTopic = mqtt:getTopic(config.mqttTopic, 0)

    config.bounce = config.bounce or 50
    config.timeUp = config.timeUp or 10000
    config.timeDown = config.timeDown or 10000

    local motorState
    local state =
        RollerState:new(
        {
            timeUp = config.timeUp,
            timeDown = config.timeDown,
            callback = function(pos, motor, state)
                motorState = motor
                if motor == RollerState.MOTOR_STATUS_UP then
                    outputDown:off()
                    outputUp:on()
                elseif motor == RollerState.MOTOR_STATUS_DOWN then
                    outputUp:off()
                    outputDown:on()
                else
                    outputDown:off()
                    outputUp:off()
                end
                statusTopic:publish(pos and tostring(pos) or "UNDEF")
                log:info("pos=%s", tostring(pos))
            end
        }
    )
    local inputUp =
        PushButton:new(
        {
            pin = inputUpPin,
            bounce = config.bounce,
            callback = function()
                if motorState == RollerState.MOTOR_STATUS_STOP then
                    state:setpos(0)
                else
                    state:stop()
                end
            end
        }
    )
    local inputDown =
        PushButton:new(
        {
            pin = inputDownPin,
            bounce = config.bounce,
            callback = function()
                if motorState == RollerState.MOTOR_STATUS_STOP then
                    state:setpos(100)
                else
                    state:stop()
                end
            end
        }
    )

    local commandTopic =
        mqtt:subscribe(
        config.mqttTopic .. "/set",
        0,
        function(data)
            local pos = tonumber(data)
            if pos == nil and data == "STOP" then
                state:stop()
            else
                state:setpos(pos)
            end
        end
    )

    mqtt:runOnConnect(
        function(reconnect)
            statusTopic:publish(state.state)
        end
    )

    log:info(
        "Init: InputUp %d (%s, pin %d) -> OutputUp %d (%s, pin %d), t=%d",
        config.inputUp,
        portmap.inputs[config.inputUp].name,
        inputUpPin,
        config.outputUp,
        portmap.outputs[config.outputUp].name,
        outputUpPin,
        config.timeUp
    )
    log:info(
        "Init: InputDown %d (%s, pin %d) -> OutputDown %d (%s, pin %d), t=%d",
        config.inputDown,
        portmap.inputs[config.inputDown].name,
        inputDownPin,
        config.outputDown,
        portmap.outputs[config.outputDown].name,
        outputDownPin,
        config.timeDown
    )
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

function App:ui()
    local this = self
    if self._ui == nil then
        self._ui = {
            actions = {
                {
                    type = "button",
                    label = "UP",
                    action = function()
                        this.state:up()
                    end
                },
                {
                    type = "button",
                    label = "DOWN",
                    action = function()
                        this.state:down()
                    end
                }
            },
            dashboard = {
                {
                    type = "value",
                    label = "STATUS",
                    value = function()
                        return this.state.state
                    end
                }
            }
        }
    end
    return self._ui
end

return App
