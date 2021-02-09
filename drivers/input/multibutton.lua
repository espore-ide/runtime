local HoldButton = require("drivers.input.holdbutton")

local MultiButton = {}

-- new() configures an input as a multibutton
-- config:
-- pin: the pin to configure as a push button
-- bounce: the filter period to wait until an interrupt is considered an actual push of a button
-- callback: the function to invoke once a real push is detected.

function MultiButton:new(config)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    local count = 0
    o.timer = tmr.create()
    o.timer:register(config.multiClickTimeout, tmr.ALARM_SEMI, function()
        config.callback(count)
        count = 0
    end)
    config.multiClickTimeout = config.multiClickTimeout or 500
    config.longPress = config.longPress or 500
    config.bounce = config.bounce or 500
    config.confidence = config.confidence or 0.2
    self._hb = HoldButton:new({
        pin = config.pin,
        bounce = config.bounce,
        confidence = config.confidence,
        timerResolution = config.timerResolution,
        callback = function(state, time)
            if state == 0 then return end
            if count == 0 and time >= config.longPress then
                config.callback(0)
            else
                count = count + 1
                o.timer:stop()
                o.timer:start()
            end

        end
    })
    return o
end

function MultiButton:destroy()
    self._hb:destroy()
    self._hb = nil
    self.timer:stop()
    self.timer:unregister()
end

return MultiButton
