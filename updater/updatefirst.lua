local M = {}
local Event = require("core.event")
local WifiManager = require("wifi.manager")
local pkg = require("core.pkg")

M.OnUpdate = Event:new()

local log = require("core.log"):new("updatefirst")

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

local function startpolling(info, reconnect)
    WifiManager.OnConnect:unlisten(startpolling)
    startpolling = nil
    pkg.unload("updatefirst")
    if reconnect then
        return
    end
    local updater = pkg.require("updater.updater", true)
    tmr.create():alarm(
        60000,
        tmr.ALARM_AUTO,
        function()
            log:info("Polling for updates...")
            updater.update(
                function(err)
                    if type(err) == "string" then
                        log:error("Update result: %s", err)
                    else
                        log:info("Finished polling for updates...")
                    end
                end
            )
        end
    )
end

WifiManager.OnConnect:listen(startpolling)

return M
