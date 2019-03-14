local Debounced = require("debounced")

local PB = {}

function PB:new(pin, bounce, callback)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.callback = callback
    Debounced:new(
        pin,
        bounce,
        function(state)
            if state == 0 then
                callback()
            end
        end
    )
end

return PB
