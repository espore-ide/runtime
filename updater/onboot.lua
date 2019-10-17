local M = {}
local Event = require("core.event")
local WifiManager = require("wifimanager.wifimanager")
M.OnUpdate = Event:new()

local log = require("core.log"):new("update.onboot")

local function updateonboot(info, reconnect)
    WifiManager.OnConnect:unlisten(updateonboot)
    updateonboot = nil
    local updater = require("updater.updater")
    updater.unrequire("update.onboot")
    if reconnect then
        return
    end

    log:info("Checking for updates...")
    updater.check(
        function(result)
            local pformat = require("core.stringutil").pformat
            local err
            if type(result) == "string" then
                err = pformat("Error updating device: %s", result)
                log:error(err)
            else
                if result == updater.RESULT_NEW_IMAGE then
                    log:info("New image found. Restarting in 5 seconds...", result)
                    tmr.create():alarm(
                        5000,
                        tmr.ALARM_SINGLE,
                        function()
                            node.restart()
                        end
                    )
                else
                    log:info("No updates found")
                end
                err = nil
            end
            M.OnUpdate:fire(err)
        end
    )
end

WifiManager.OnConnect:listen(updateonboot)

return M
