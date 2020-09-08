-- ToggleState represents a state machine of a toggled button
-- Invokes the callback when the status changes
local ToggleState = {}

ToggleState.STATUS_OFF = "OFF"
ToggleState.STATUS_ON = "ON"

-- config:
-- callback: (function) Function to call on state change
-- state: initial state
function ToggleState:new(config)
    local o = {
        state = config.state or ToggleState.STATUS_OFF,
        callback = config.callback
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function ToggleState:set(state)
    self.state = state
    if self.callback ~= nil then self.callback(state) end
end

function ToggleState:toggle()
    self:set(self.state == ToggleState.STATUS_ON and ToggleState.STATUS_OFF or
                 ToggleState.STATUS_ON)
end

function ToggleState:destroy() end

return ToggleState
