local ToggleSwitch = {}

function ToggleSwitch:new(dInput)
    local o = {state = "OFF"}
    setmetatable(o, self)
    self.__index = self
    dInput.callback = function(pinState)
        if pinState == 0  then
            local newState
            if o.state == "ON" then
                newState = "OFF"
            else
                newState = "ON"
            end
            o:set(newState)
        end
    end
    return o
end

function ToggleSwitch:set(state)
    self.state = state
    if self.callback ~= nil then
        self.callback(state)
    end
end

return ToggleSwitch
