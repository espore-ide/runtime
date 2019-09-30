-- ToggleSwitch monitors a pin for button presses,
-- keeping a state. Invokes the callback when the status changes

local PushButton = require("pushbutton")
local ToggleSwitch = {}

ToggleSwitch.STATUS_OFF = 0
ToggleSwitch.STATUS_ON = 1

-- config:
-- pin: pin to bind the switch to
-- bounce: (ms) debounce period
-- callback: (function) Function to call on state change
function ToggleSwitch:new(config)
    local o = {state = ToggleSwitch.STATUS_OFF}
    setmetatable(o, self)
    self.__index = self
    o.callback = config.callback
    o._pb=PushButton:new(
        {
            pin = config.pin,
            bounce = config.bounce,
            callback = function()
                local newState
                if o.state == ToggleSwitch.STATUS_ON then
                    newState = ToggleSwitch.STATUS_OFF
                else
                    newState = ToggleSwitch.STATUS_ON
                end
                o:set(newState)
            end
        }
    )
    return o
end

function ToggleSwitch:set(state)
    self.state = state
    if self.callback ~= nil then
        self.callback(state)
    end
end

function ToggleSwitch:destroy()
    self._pb:destroy()
    self._pb=nil
end

return ToggleSwitch
