local ToggleState = require("state.toggle")
local PushButton = require("drivers.input.pushbutton")
local OnOff = require("drivers.output.onoff")
local log = require("core.log")
local mqtt = require("mqtt.service")

local ok, portmap = pcall(require, "portmap.portmap")
if not ok then error("Toggle: Cannot load portmap: " .. portmap) end

local App = {}

function App:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function App:init(config)
    local outputPin = portmap.outputPin(config.output)
    local inputPin = portmap.inputPin(config.input)
    local log = log:new("apps.toggle/" .. self.name)
    local output = OnOff:new({pin = outputPin})
    local statusTopic = mqtt:getTopic(config.mqttTopic, 0)
    local this = self

    local state = ToggleState:new({
        callback = function(status)
            if status == ToggleState.STATUS_ON then
                output:on()
            else
                output:off()
            end
            statusTopic:publish(status, 0, true)
            log:info(status)
        end
    })
    local input = PushButton:new({
        pin = inputPin,
        bounce = config.bounce or 50,
        callback = function() state:toggle() end
    })
    local commandTopic = mqtt:subscribe(config.mqttTopic .. "/set", 0,
                                        function(data)
        if data == ToggleState.STATUS_ON then
            state:set(ToggleState.STATUS_ON)
        else
            state:set(ToggleState.STATUS_OFF)
        end
    end)

    mqtt:runOnConnect(function(reconnect)
        statusTopic:publish(state.state, 0, true)
        local hass = require("integration.hass")
        hass.publishConfig({
            component = hass.LIGHT,
            objectId = this.name,
            config = {
                name = this.description,
                unique_id = this.name,
                command_topic = mqtt.base .. config.mqttTopic .. "/set",
                state_topic = mqtt.base .. config.mqttTopic,
                payload_on = "ON",
                payload_off = "OFF"
            }
        })
    end)

    log:info("Init: Input %d (%s, pin %d) -> Output %d (%s, pin %d)",
             config.input, portmap.inputs[config.input].name, inputPin,
             config.output, portmap.outputs[config.output].name, outputPin)
    self.output = output
    self.input = input
    self.state = state
end

function App:terminate()
    self.input:destroy()
    self.output:destroy()
    self.state:destroy()
    self.input = nil
    self.output = nil
    self.state = nil
end

return App
