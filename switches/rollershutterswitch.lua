RSS = {}

RSS.STATUS_IDLE = "IDLE"
RSS.STATUS_UP = "UP"
RSS.STATUS_DOWN = "DOWN"

function RSS:new(upTime, downTime, callback)
    local o = {}
    o.timer = tmr.create()
    o.state = RSS.STATUS_IDLE
    o.upTime = upTime
    o.downTime = downTime
    o.callback = callback
    setmetatable(o, self)
    self.__index = self
    return o
end

function RSS:set(state)
    self.state = state
    self.timer:stop()
    self.timer:unregister()
    self.callback(state)
end

function RSS:activate(state, time)
    if self.state == RSS.STATUS_IDLE then
        self:set(state)
        self.timer:register(
            time,
            tmr.ALARM_SINGLE,
            function()
                self:set(RSS.STATUS_IDLE)
            end
        )
        self.timer:start()
    else
        self:set(RSS.STATUS_IDLE)
    end
end

function RSS:up()
    self:activate(RSS.STATUS_UP, self.upTime)
end

function RSS:down()
    self:activate(RSS.STATUS_DOWN, self.downTime)
end

return RSS
