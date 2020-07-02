local updater = require("updater")
local pformat = require("stringutil").pformat

function unrequire(m)
    package.loaded[m] = nil
    _G[m] = nil
end

local count = 0
local finish

local function updaterTest()
    count = count + 1
    print(pformat("Starting test #%d", count))
    updater.check("192.168.1.34", 8080, "", function(err)
        print(pformat("Update result: %s", err))
        tmr.create():alarm(10, tmr.ALARM_SINGLE, finish)
    end)
end

finish = function()
    collectgarbage()
    print(pformat("Finished test #%d. Heap: %d", count, node.heap()))
    if count < 1 then
        updaterTest()
    else
        print("end---")
    end
end

collectgarbage()
print(pformat("Initial heap: %d", node.heap()))
updaterTest()
