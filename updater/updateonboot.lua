local M = {}
local Event = require("event")
local WifiManager = require("wifimanager")
M.OnUpdate = Event:new()

local log = require("log"):new("updateonboot")

local function updateonboot(info, reconnect)
    WifiManager.OnConnect:unlisten(updateonboot)
    updateonboot = nil
    local updater = require("updater")
    updater.unrequire("updateonboot")
    if reconnect then
        return
    end

    log:info("Checking for updates...")
    updater.check(
        function(result)
            local pformat = require("stringutil").pformat
            local err
            if type(result) == "string" then
                err = pformat("Error updating device: %s", result)
                log:error(err)
            else
                if result > 0 then
                    log:info("%d files updated. Restarting in 5 seconds...", result)
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
