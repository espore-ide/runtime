-- OnOff configures a pin as output, tracking its state
local OnOff = {}
OnOff.STATE_ON = 1
OnOff.STATE_OFF = 0

-- new() creates a OnOff-controlled pin instance
-- config:
-- pin: the pin to watch and configure as output
function OnOff:new(config)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.pin = config.pin

    if gpio.mode == nil then
        gpio.config({gpio = config.pin, dir = gpio.OUT})
    else
        gpio.mode(config.pin, gpio.OUT)
    end
    o:off()
    return o
end

function OnOff:set(state)
    gpio.write(self.pin, state)
    self.state = state
end

function OnOff:on() self:set(OnOff.STATE_ON) end

function OnOff:off() self:set(OnOff.STATE_OFF) end

function OnOff:destroy() end

return OnOff
