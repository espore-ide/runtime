-- TODO: adapt the below to be a state machine

CountSwitch = {}
function CountSwitch:new(dInput, interval)
    local o = {count = 0}
    setmetatable(o, self)
    self.__index = self
    o.timer = tmr.create()
    o.timer:register(
        interval,
        tmr.ALARM_SEMI,
        function()
            if o.callback ~= nil then
                o.callback(o)
            end
            o.count = 0
        end
    )

    dInput.callback = function(pinState)
        if pinState ~= 0 then
            o.count = o.count + 1
            o.timer:stop()
            o.timer:start()
        end
    end
    return o
end
return CountSwitch
