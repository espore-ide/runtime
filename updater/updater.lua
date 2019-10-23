-- datafile: updater-etag.json

local Updater = {}
local pkg = require("core.pkg")
local pformat = pkg.require("core.stringutil").pformat
local json = pkg.require("core.json")
local log = pkg.require("core.log"):new("updater")
local downloader = pkg.require("updater.downloader", true)

local CONFIG_FILE = "updater-config.json"
local ETAG_FILE = "updater-etag.json"
local IMAGE_FILE = "update.img"

local config = json.read(CONFIG_FILE)
if config == nil then
    error("Updater: Cannot read " .. CONFIG_FILE)
end

local function readEtag()
    return json.read(ETAG_FILE) or {AppETag = "", NodeMCUETag = ""}
end

local function writeEtag(etag)
    json.write(ETAG_FILE, etag)
end

local function restart()
    log:warning("Restarting in 5 seconds ...")
    tmr.create():alarm(
        5000,
        tmr.ALARM_SINGLE,
        function()
            node.restart()
        end
    )
end

Updater.RESULT_NO_UPDATES = 0
Updater.RESULT_NEW_IMAGE = 1

Updater.check = function(callback)
    local fm
    local etag = readEtag()
    local imgFile = pformat("%s.img", node.chipid())
    local f
    local hasher
    downloader.download(
        config.host,
        config.port,
        config.basePath .. imgFile,
        etag.AppETag,
        function(data)
            if f == nil then
                f = file.open(IMAGE_FILE, "w")
                hasher = crypto.new_hash("SHA1")
            end
            f:write(data)
            hasher:update(data)
        end,
        function(err, length, newEtag)
            local hash
            if f ~= nil then
                f:close()
                hash = hasher:finalize()
                hash = encoder.toHex(hash)
                f = nil
                hasher = nil
            end
            if err == 304 then
                callback(Updater.RESULT_NO_UPDATES)
                return
            end
            if err ~= nil then
                callback(err)
                return
            end
            etag.AppETag = newEtag
            writeEtag(etag)
            callback(Updater.RESULT_NEW_IMAGE)
        end
    )
end

Updater.checkNodeMCU = function(callback)
    local fm
    local etag = readEtag()
    local imgFile = pformat("%s.bin", node.chipid())
    local started = false
    local bytes = 0
    local lastBytes = 0

    downloader.download(
        config.host,
        config.port,
        config.basePath .. imgFile,
        etag.NodeMCUETag,
        function(data)
            if not started then
                started = true
                local ok, err = pcall(otaupgrade.commence)
                if not ok then
                    callback(pformat("Error commencing NodeMCU firmware upgrade: %s", err))
                    return
                end
                log:info("Commencing NodeMCU firmware update...")
            end
            local ok, err = pcall(otaupgrade.write, data)
            if not ok then
                callback(pformat("Error writing NodeMCU update data: %s", err))
                return
            end
            bytes = bytes + #data
            if bytes - lastBytes > 100000 then
                log:info("Downloaded %d bytes", bytes)
                lastBytes = bytes
            end
        end,
        function(err, length, newEtag)
            if err == 304 then
                callback(Updater.RESULT_NO_UPDATES)
                return
            end
            if err ~= nil then
                callback(err)
                return
            end
            local ok, err = pcall(otaupgrade.complete, 0)
            if not ok then
                callback(pformat("Error finalizing NodeMCU firmware upgrade: %s", err))
                return
            end
            etag.NodeMCUETag = newEtag
            writeEtag(etag)
            callback(Updater.RESULT_NEW_IMAGE)
        end
    )
end

Updater.update = function(callback)
    local function checkForFirmwareUpdates(callback)
        log:info("Checking for firmware updates...")
        Updater.checkNodeMCU(
            function(result)
                if type(result) == "string" then
                    log:error("Error updating device firmware: %s", result)
                else
                    if result == Updater.RESULT_NEW_IMAGE then
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
        Updater.check(
            function(result)
                local err
                if type(result) == "string" then
                    log:error("Error updating device: %s", result)
                else
                    if result == Updater.RESULT_NEW_IMAGE then
                        log:info("New application image found.")
                        restart()
                        return
                    else
                        if result == Updater.RESULT_NO_UPDATES then
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
                    callback(err)
                end
            )
        end
    )
end

return Updater
