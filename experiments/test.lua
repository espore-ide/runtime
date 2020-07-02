local defer = require("core.defer")
local i = 0
func = function()
    i = i + 1
    print(i)
    -- node.task.post(node.task.LOW_PRIORITY, func)
    if i < 8000 then defer(func) end
end

func()
