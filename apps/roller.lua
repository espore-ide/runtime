local RollerState = require("state.roller")
local PushButton = require("drivers.input.pushbutton")
local OnOff = require("drivers.output.onoff")
local portmap = require("portmap.portmap")
local log = require("core.log")

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
    config.bounce = config.bounce or 50
    config.timeUp = config.timeUp or 10000
    config.timeDown = config.timeDown or 10000

    local state =
        RollerState:new(
        {
            timeUp = config.timeUp,
            timeDown = config.timeDown,
            callback = function(status)
                if status == RollerState.STATUS_UP then
                    outputDown:off()
                    outputUp:on()
                    log:info("UP")
                elseif status == RollerState.STATUS_DOWN then
                    outputUp:off()
                    outputDown:on()
                    log:info("DOWN")
                else
                    outputDown:off()
                    outputUp:off()
                    log:info("IDLE")
                end
            end
        }
    )
    local inputUp =
        PushButton:new(
        {
            pin = inputUpPin,
            bounce = config.bounce,
            callback = function()
                state:up()
            end
        }
    )
    local inputDown =
        PushButton:new(
        {
            pin = inputDownPin,
            bounce = config.bounce,
            callback = function()
                state:down()
            end
        }
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

return App
