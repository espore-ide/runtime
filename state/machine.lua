SM = {}
local pformat = require("core.stringutil").pformat

-- new creates a new state machine
SM.TRIG_TIMEOUT = "timeout"
SM.TRIG_REDIRECT = "redirect"

function SM:new(config)
    local o = {states = {}}
    for name, state in pairs(config.states) do
        if type(state) == "function" then
            local s = {name = name}
            state(s)
            state = s
        else
            state.name = name
        end
        o.states[name] = state
    end
    setmetatable(o, self)
    self.__index = self
    o:set(config.start)
    return o
end
-- get returns the state with the given name
-- Throws in case the state does not exist
function SM:get(stateName)
    local state = self.states[stateName]
    if state == nil then error(pformat("Unknown state: %s", stateName)) end
    return state
end

-- set forces the given state
-- stateName: state to transition to
-- trigger: The trigger that started the transition
-- parm: parameter passed to the trigger
function SM:set(stateName, trigger, parm)
    if self.timer then self.timer:unregister() end
    -- invoke current state exit handler, if any:
    local state = self:get(stateName)
    if self.current and self.current.exit then
        self.current.exit(stateName, trigger)
    end
    oldState = self.current
    self.current = state
    -- invoke the new state's enter handler, if any
    if state.enter then
        local redirect
        -- a state may redirect to another during the enter handler:
        redirect, parm = state.enter(parm, trigger, oldState)
        if redirect then
            self:set(redirect, SM.TRIG_REDIRECT, parm)
            return
        end
    end
    -- a state may define a timeout in case no other trigger fires:
    local timeout = state.triggers[SM.TRIG_TIMEOUT]
    if timeout and type(timeout) == "table" then
        if timeout.time == 0 then
            self:set(timeout.target, SM.TRIG_TIMEOUT)
        else
            if self.timer == nil then self.timer = tmr.create() end
            self.timer:alarm(timeout.time, tmr.ALARM_SINGLE, function()
                self:set(timeout.target, SM.TRIG_TIMEOUT, timeout.parm)
            end)
        end
    end
end

-- setTimeout allows for defining the current state's timeout dynamically
function SM:setTimeout(time, target, parm)
    timeout = self.current.triggers[SM.TRIG_TIMEOUT] or {}
    timeout.time = time or timeout.time
    timeout.target = target or timeout.target
    timeout.parm = parm or timeout.parm
    self.current.triggers[SM.TRIG_TIMEOUT] = timeout
end

-- trigger transitions to the next state according to the passed trigger name
-- trigger: Name of the trigger to fire
-- parm: Parameter for this trigger (will be passed to the target state's enter() handler)
function SM:trigger(trigger, parm)
    local newState = self.current.triggers[trigger]
    if type(newState) == "function" then newState, parm = newState(parm) end
    if type(newState) == "table" and newState.target then
        newState = newState.target
    end
    if newState == nil then return end
    self:set(newState, trigger, parm)
end

return SM
