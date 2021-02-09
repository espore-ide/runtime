-- Holdbutton configures an input pin as a held push button
-- a push button will invoke the callback only when the corresponding
-- input has been set low for the debounce period
local Debounced = require("drivers.input.debounced")

local HoldButton = {}

-- new() configures an input as a push buton
-- config:
-- pin: the pin to configure as a push button
-- bounce: the filter period to wait until an interrupt is considered an actual push of a button
-- callback: the function to invoke once a real push is detected.
function HoldButton:new(config)
    local o = {}
    o.timer = tmr.create()

    local avg = 0
    local buttonDown = false
    local timeHeld = 0

    config.confidence = config.confidence or 0.99
    config.timerResolution = config.timerResolution or 50

    o.timer:register(config.timerResolution, tmr.ALARM_AUTO, function()
        avg = (avg + gpio.read(config.pin)) / 2
        timeHeld = timeHeld + config.timerResolution
        if avg > config.confidence then
            buttonDown = false
            o.timer:stop()
            config.callback(1, timeHeld)
        end
    end)

    setmetatable(o, self)
    self.__index = self
    self._db = Debounced:new({
        pin = config.pin,
        bounce = config.bounce,
        callback = function(state)
            if state == 0 and not buttonDown then
                buttonDown = true
                avg = 0
                timeHeld = 0
                o.timer:start()
                config.callback(0)
            end
        end
    })
    return o
end

function HoldButton:destroy()
    self._db:destroy()
    self._db = nil
    self.timer:stop()
    self.timer:unregister()
    self.timer = nil
end

return HoldButton
