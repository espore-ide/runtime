Debounced = {}

function Debounced:new(pin, bounce)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.timer = tmr.create()
    o.timer:register(bounce, tmr.ALARM_SEMI, function()
        if o.callback ~= nil then
            o.callback(gpio.read(pin))
        end
    end)

    local intfunc=function() o.timer:start() end
    
    if gpio.mode == nil then
        gpio.config( {gpio=pin, dir=gpio.IN, pull=gpio.PULL_UP })
        gpio.trig(pin, gpio.INTR_UP_DOWN, intfunc)
    else
        gpio.mode(pin, gpio.INT, gpio.PULLUP)
        gpio.trig(pin, "both", intfunc)
    end
    return o
end

return Debounced
