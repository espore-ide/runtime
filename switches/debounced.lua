-- Debounced configures a pin as input with interrupts and invokes a callback
-- with the debounced (filtered) final state

local Debounced = {}

-- new() creates a debounced pin instance
-- config:
-- pin: the pin to watch and configure as input
-- bounce: in milliseconds, the time to wait until reading the final state
-- callback: the function to invoke with the final state.
function Debounced:new(config)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.timer = tmr.create()
    o.timer:register(
        config.bounce,
        tmr.ALARM_SEMI,
        function()
            if config.callback ~= nil then
                config.callback(gpio.read(config.pin))
            end
        end
    )

    local intfunc = function()
        o.timer:start()
    end

    if gpio.mode == nil then
        gpio.config({gpio = config.pin, dir = gpio.IN, pull = gpio.PULL_UP})
        gpio.trig(config.pin, gpio.INTR_UP_DOWN, intfunc)
    else
        gpio.mode(config.pin, gpio.INT, gpio.PULLUP)
        gpio.trig(config.pin, "both", intfunc)
    end
    return o
end

function Debounced:destroy()
    self.timer:stop()
    self.timer:unregister()
    self.timer=nil
end

return Debounced
