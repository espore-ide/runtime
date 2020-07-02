-- Roller state machine models a roller shutter state machine
-- The states are "idle", "going up" and "going down"
-- The amount of time in each up/down states can be set by configuration
RSS = {}

RSS.STATUS_IDLE = "IDLE"
RSS.STATUS_UP = "UP"
RSS.STATUS_DOWN = "DOWN"

-- config:
-- timeUp: Time in the up state before going idle
-- timeDown: Time in the down state before going idle
-- callback: Function to call when there are state changes

-- new creates a new state machine
function RSS:new(config)
    local o = {}
    o.timer = tmr.create()
    o.state = RSS.STATUS_IDLE
    o.timeUp = config.timeUp
    o.timeDown = config.timeDown
    o.callback = config.callback
    setmetatable(o, self)
    self.__index = self
    return o
end

-- set (private) forces a particular state, coming from any other state
function RSS:set(state)
    self.state = state
    self.timer:stop()
    self.timer:unregister()
    self.callback(state)
end

-- activate (private) kicks off up or down
function RSS:activate(state, time)
    if self.state == RSS.STATUS_IDLE then
        self:set(state)
        self.timer:register(time, tmr.ALARM_SINGLE,
                            function() self:set(RSS.STATUS_IDLE) end)
        self.timer:start()
    else
        self:set(RSS.STATUS_IDLE)
    end
end

-- up switches the machine to the "going up" state
function RSS:up() self:activate(RSS.STATUS_UP, self.timeUp) end

-- down switches the machine to the "going down" state
function RSS:down() self:activate(RSS.STATUS_DOWN, self.timeDown) end

function RSS:stop() self:set(RSS.STATUS_IDLE) end

function RSS:destroy()
    self.timer:stop()
    self.timer:unregister()
    self.timer = nil
end

return RSS
