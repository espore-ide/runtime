local M = {}
local Event = require("core.event")
local WifiManager = require("wifi.manager")
local pkg = require("core.pkg")

M.OnUpdate = Event:new()

local log = require("core.log"):new("update.onboot")

local function restart()
    log:warning("Restarting in 5 seconds...", result)
    tmr.create():alarm(
        5000,
        tmr.ALARM_SINGLE,
        function()
            node.restart()
        end
    )
end

local function updateonboot(info, reconnect)
    WifiManager.OnConnect:unlisten(updateonboot)
    updateonboot = nil
    pkg.unload("updater.onboot")
    if reconnect then
        return
    end
    pkg.require("updater.updater", true).update(
        function(err)
            M.OnUpdate:fire(err)
        end
    )
end

WifiManager.OnConnect:listen(updateonboot)

return M
