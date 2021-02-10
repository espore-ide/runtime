local MultiButton = require("drivers.input.multibutton")
local mbtrigger = require("drivers.output.mbtrigger")
local log = require("core.log")

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
    local inputPin = portmap.inputPin(config.input)
    local log = log:new("apps.multibutton/" .. self.name)
    local this = self

    local input = MultiButton:new({
        pin = inputPin,
        bounce = config.bounce or 50,
        multiClickTimeout = config.multiClickTimeout or 500,
        longPress = config.longPress or 500,
        callback = mbtrigger(this.name, this.description, config.mqttTopic)
    })

    log:info("Init Multibutton: Input %d (%s, pin %d)", config.input,
             portmap.inputs[config.input].name, inputPin)

    self.input = input
    self.state = state
end

function App:terminate()
    self.input:destroy()
    self.input = nil
end

return App
