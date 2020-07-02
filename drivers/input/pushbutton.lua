-- PushButton configures an input pin as a push button
-- a push button will invoke the callback only when the corresponding
-- input has been set low for the debounce period
local Debounced = require("drivers.input.debounced")

local PushButton = {}

-- new() configures an input as a push buton
-- config:
-- pin: the pin to configure as a push button
-- bounce: the filter period to wait until an interrupt is considered an actual push of a button
-- callback: the function to invoke once a real push is detected.
function PushButton:new(config)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    self._db = Debounced:new({
        pin = config.pin,
        bounce = config.bounce,
        callback = function(state)
            if state == 0 then config.callback() end
        end
    })
    return o
end

function PushButton:destroy()
    self._db:destroy()
    self._db = nil
end

return PushButton
