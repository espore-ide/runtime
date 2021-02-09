local MultiButton = require("drivers.input.multibutton")
local log = require("core.log")
local mqtt = require("mqtt.service")
local defer = require("core.defer")

local ok, portmap = pcall(require, "portmap.portmap")
if not ok then error("Toggle: Cannot load portmap: " .. portmap) end

local App = {}

function App:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

local count2type = {
    "button_long_press", "button_short_press", "button_double_press",
    "button_triple_press", "button_quadruple_press", "button_quintuple_press"
}

function App:init(config)
    local inputPin = portmap.inputPin(config.input)
    local log = log:new("apps.multibutton/" .. self.name)
    local statusTopic = mqtt:getTopic(config.mqttTopic, 0)
    local this = self

    local input = MultiButton:new({
        pin = inputPin,
        bounce = config.bounce or 50,
        multiClickTimeout = config.multiClickTimeout or 500,
        longPress = config.longPress or 500,
        callback = function(count)
            local type = count2type[count + 1]
            if type ~= nil then statusTopic:publish(type) end
        end
    })

    mqtt:runOnConnect(function(reconnect)
        local hass = require("integration.hass")
        for _, type in ipairs(count2type) do
            defer(function()
                hass.publishConfig({
                    component = hass.DEVICE_AUTOMATION,
                    objectId = hass.hclean(this.name .. "_" .. type),
                    config = {
                        automation_type = "trigger",
                        topic = mqtt.base .. config.mqttTopic,
                        payload = type,
                        type = type,
                        subtype = this.description
                    }
                })
            end)
        end
    end)

    log:info("Init Multibutton: Input %d (%s, pin %d)", config.input,
             portmap.inputs[config.input].name, inputPin)
    self.output = output
    self.input = input
    self.state = state
end

function App:terminate()
    self.input:destroy()
    self.input = nil
end

return App
