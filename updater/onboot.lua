local M = {}
local Event = require("core.event")
local WifiManager = require("wifi.manager")
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
    local updater = require("updater.updater")
    require("core.pkg").unload("updater.onboot")
    if reconnect then
        return
    end

    local function checkForFirmwareUpdates(callback)
        log:info("Checking for firmware updates...")
        updater.checkNodeMCU(
            function(result)
                if type(result) == "string" then
                    log:error("Error updating device firmware: %s", result)
                else
                    if result == updater.RESULT_NEW_IMAGE then
                        log:info("New NodeMCU firmware image has been flashed.")
                        restart()
                        return
                    else
                        log:info("No NodeMCU firmware updates found")
                        otaupgrade.accept()
                    end
                end
                callback()
            end
        )
    end

    local function checkForAppUpdates(callback)
        log:info("Checking for application updates...")
        updater.check(
            function(result)
                local err
                if type(result) == "string" then
                    log:error("Error updating device: %s", result)
                else
                    if result == updater.RESULT_NEW_IMAGE then
                        log:info("New application image found.")
                        restart()
                        return
                    else
                        if result == updater.RESULT_NO_UPDATES then
                            log:info("No updates found")
                            if __FIRMWARE_ACCEPT == false then
                                __FIRMWARE_ACCEPT = true
                                log:info("Accepting application firmware")
                            end
                        else
                            log:error("Error checking for updates: %s", result)
                        end
                    end
                    err = nil
                end
                callback(err)
            end
        )
    end

    checkForFirmwareUpdates(
        function()
            checkForAppUpdates(
                function(err)
                    M.OnUpdate:fire(err)
                end
            )
        end
    )
end

WifiManager.OnConnect:listen(updateonboot)

return M
