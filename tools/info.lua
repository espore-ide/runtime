local mqtt = require("mqtt.service")

local M = {}
local subs = {}

M.update = function()
    local info = {}
    for name, cb in pairs(subs) do
        local i = cb()
        if type(i) == "table" then
            for k, v in pairs(i) do info[name .. "_" .. k] = v end
        end
    end
    mqtt:publish("espore/" .. firmware.name .. "/sys/info", sjson.encode(info),
                 0, true)
end

M.subscribe = function(name, callback) subs[name] = callback end

return M
