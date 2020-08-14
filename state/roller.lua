local machine = require("state.machine")

-- Roller state machine models a roller shutter state machine
-- The state machine invokes a callback indicating the shutter position and
-- requested motor direction
-- The amount of time to open/close the shutter can be set by configuration
-- Desired position of the shutter can be set as a 0-100 number: 0 fully open, 100 fully closed

RSS = {}

-- Possible motor states:
RSS.MOTOR_STATUS_STOP = "STOP"
RSS.MOTOR_STATUS_UP = "UP"
RSS.MOTOR_STATUS_DOWN = "DOWN"

local TRIG_STOP = "stop"
local TRIG_SET_POS = "setpos"

local STATE_UNDEF = "UNDEF" -- Starting state. We don't know the actual position of the shutter
local STATE_FULLY_OPENING = "FULLY OPENING" -- opening the shutter all the way
local STATE_FULLY_CLOSING = "FULLY CLOSING" -- closing the shutter all the way
local STATE_HOMING = "HOMING" -- opening the shutter to sync this state machine with the shutter
local STATE_POSITIONED = "POSITIONED" -- we know where the shutter is
local STATE_CLOSING = "CLOSING" -- closing the shutter towards the requested position
local STATE_OPENING = "OPENING" -- opening the shutter towards the requested position
local STATE_CHECKDIR = "C" -- intermediate state to decide whether to open or close
local STATE_UNDEF_CHECKDIR = "U" -- intermediate state to decide whether to open or close, when we don't know the current position

-- normalizePos ensures the shutter position is kept within boundaries
function normalizePos(pos) return pos > 100 and 100 or (pos < 0 and 0 or pos) end

function round(x) return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5) end

-- config:
-- timeUp: Time in the up state before going idle
-- timeDown: Time in the down state before going idle
-- timeSlack: Extra time to add to make sure endstop is reached when going fully open or closed
-- callback: Function to call when there are state changes

-- new creates a new state machine
function RSS:new(config)
    config.timeSlack = config.timeSlack or 0
    local o = {}
    -- wrap callback so we return rounded shutter positions
    local callback = function(pos, motor, stateName)
        config.callback(pos and round(pos), motor, stateName)
    end
    -- currentPos estimates the current shutter position based on when it started moving
    -- and how long it takes for it to reach one or other end.
    local currentPos = function(dir, time, timestamp)
        local elapsed = (node.uptime() - timestamp) / 1000
        return normalizePos(o.pos + dir * 100 * elapsed / time)
    end

    o.reportTimer = tmr.create()
    -- startReporting ticks every second with the estimated shutter position
    local startReporting = function(motor, stateName, dir, time, timestamp)
        o.reportTimer:alarm(1000, tmr.ALARM_AUTO, function()
            callback(currentPos(dir, time, timestamp), motor, stateName)
        end)
    end
    -- stopReporting stops the reporting timer
    local stopReporting = function() o.reportTimer:unregister() end

    -- fullyOpenCloseState builds the state handler for STATE_FULLY_OPENING and _CLOSING
    -- motor: motor state for this state (RSS.MOTOR_STATUS_UP or DOWN)
    -- targetPos: 0 for fully open, and 100 for fully closed
    -- time: The time it takes to move the shutter in this direction
    local fullyOpenCloseState = function(motor, targetPos, time)
        return function(state)
            state.enter = function()
                callback(o.pos, motor, state.name)
            end
            state.exit = function() o.pos = targetPos end
            state.triggers = {
                -- if stopped, back to undefined state:
                [TRIG_STOP] = STATE_UNDEF,
                -- if a specific position is set, then we need to home the shutter first:
                [TRIG_SET_POS] = STATE_UNDEF_CHECKDIR,
                -- if we are able to stay for the full time, then we know the position:
                timeout = {
                    time = time + config.timeSlack,
                    target = STATE_POSITIONED
                }
            }
        end
    end

    -- openCloseState builds the state handler for STATE_CLOSING and _OPENING
    -- motor: motor state for this state (RSS.MOTOR_STATUS_UP or DOWN)
    -- dir: -1 for opening and 1 for closing
    -- time: Time it takes to move the shutter in this direction
    local openCloseState = function(motor, dir, time)
        return function(state)
            local targetPos, timestamp
            state.enter =
                function(target) -- trigger leading to this state must have a target position parameter
                    targetPos = target
                    callback(o.pos, motor, state.name)
                    -- based on the target, estimate how long to run the shutter for
                    local timeout = time * dir * (targetPos - o.pos) / 100
                    timeout = (targetPos == 0 or targetPos == 100) and timeout +
                                  config.timeSlack or timeout
                    o.machine:setTimeout(timeout)
                    timestamp = node.uptime()
                    startReporting(motor, state.name, dir, time, timestamp)
                end
            state.exit = function(newState, exitTrigger)
                -- if we're exiting this state due to a timeout, then we're sure we reached the target position
                -- so we don't need to estimate:
                o.pos = (exitTrigger == machine.TRIG_TIMEOUT) and targetPos or
                            currentPos(dir, time, timestamp)
                stopReporting()
            end
            state.triggers = {
                -- if stopped, back to the standby state:
                [TRIG_STOP] = STATE_POSITIONED,
                -- if a specific position is set, move to CHECKDIR state to evaluate next course of action
                [TRIG_SET_POS] = STATE_CHECKDIR,
                -- in case of timeout, we're done
                timeout = {time = time, target = STATE_POSITIONED}
            }
        end
    end

    -- define the state machine
    o.machine = machine:new({
        start = STATE_UNDEF,
        states = {
            [STATE_UNDEF] = {
                enter = function()
                    o.pos = nil
                    callback(o.pos, RSS.MOTOR_STATUS_STOP, STATE_UNDEF)
                end,
                triggers = {
                    [TRIG_STOP] = STATE_UNDEF,
                    [TRIG_SET_POS] = STATE_UNDEF_CHECKDIR
                }
            },
            -- intermediate state to decide what to do if a position is requested:
            [STATE_UNDEF_CHECKDIR] = {
                enter = function(target)
                    -- if full open/close is requested, that allows us to find the position of the motor,
                    -- otherwise we'll have to fully open (homing) and then try to achieve the target position
                    return target == 100 and STATE_FULLY_CLOSING or
                               (target == 0 and STATE_FULLY_OPENING or
                                   STATE_HOMING), target
                end
            },
            -- open the shutters all the way as a way to sync with the shutter
            [STATE_HOMING] = {
                enter = function(target)
                    o.pos = nil
                    o.machine:setTimeout(nil, nil, target)
                    callback(o.pos, RSS.MOTOR_STATUS_UP, STATE_HOMING)
                end,
                exit = function(newStateName, exitTrigger)
                    if exitTrigger == machine.TRIG_TIMEOUT then
                        o.pos = 0
                    end
                end,
                triggers = {
                    [TRIG_STOP] = STATE_UNDEF,
                    [TRIG_SET_POS] = function(target)
                        o.machine:setTimeout(nil, nil, target)
                        return nil
                    end,
                    timeout = {time = config.timeUp, target = STATE_CHECKDIR}
                }
            },
            [STATE_FULLY_OPENING] = fullyOpenCloseState(RSS.MOTOR_STATUS_UP, 0,
                                                        config.timeUp),
            [STATE_FULLY_CLOSING] = fullyOpenCloseState(RSS.MOTOR_STATUS_DOWN,
                                                        100, config.timeDown),
            [STATE_POSITIONED] = {
                enter = function()
                    callback(o.pos, RSS.MOTOR_STATUS_STOP, STATE_POSITIONED)
                end,
                triggers = {
                    [TRIG_SET_POS] = STATE_CHECKDIR,
                    [TRIG_STOP] = STATE_POSITIONED
                }
            },
            [STATE_CHECKDIR] = {
                enter = function(target)
                    target = normalizePos(target)
                    return target == o.pos and STATE_POSITIONED or
                               (target > o.pos and STATE_CLOSING or
                                   STATE_OPENING), target
                end
            },
            [STATE_OPENING] = openCloseState(RSS.MOTOR_STATUS_UP, -1,
                                             config.timeUp),
            [STATE_CLOSING] = openCloseState(RSS.MOTOR_STATUS_DOWN, 1,
                                             config.timeDown)
        }
    })

    setmetatable(o, self)
    self.__index = self
    return o
end

-- set (private) forces a particular state, coming from any other state
function RSS:setpos(target) self.machine:trigger(TRIG_SET_POS, target) end
function RSS:getpos() return self.pos and round(self.pos) end
function RSS:stop() self.machine:trigger(TRIG_STOP) end

function RSS:destroy() end

return RSS
