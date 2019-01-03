ToggleSwitch = {}

function ToggleSwitch:new(dInput)
    local o = {state="OFF"}
    setmetatable(o, self)
    self.__index = self
    dInput.callback = function(pinState)
        if pinState == gpio.LOW then
            if o.state=="ON" then
                o.state="OFF"
            else
                o.state="ON"
            end
            if o.callback ~= nil then
                o.callback(o)
            end
        end
    end
    return o
end

return ToggleSwitch