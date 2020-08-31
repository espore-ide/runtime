local log = require("core.log"):new("defer")

local DEFER_TIME = 100

local first
local last

-- defer yields to the OS for 1ms and then runs func
-- return function(func, t) tmr.create():alarm(t or 1, tmr.ALARM_SINGLE, func) end

local invokeNext

invokeNext = function()
    if first == nil then return end
    local ok, err = pcall(first.handler)
    if not ok then log:error("Error calling defer handler: %s", err) end
    first = first.next
    if first == nil then
        last = nil
    else
        tmr.create():alarm(DEFER_TIME, tmr.ALARM_SINGLE, invokeNext)
    end
end

return function(func)
    local n = {handler = func}
    if first == nil then
        first = n
        tmr.create():alarm(DEFER_TIME, tmr.ALARM_SINGLE, invokeNext)
    else
        last.next = n
    end
    last = n
end
