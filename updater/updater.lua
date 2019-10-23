-- datafile: updater-etag.json

local Updater = {}
local pformat = require("core.stringutil").pformat
local json = require("core.json")

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

Updater.RESULT_NO_UPDATES = 0
Updater.RESULT_NEW_IMAGE = 1

Updater.check = function(callback)
    local fm
    local etag = readEtag()
    local downloader = require("updater.downloader")
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
    local downloader = require("updater.downloader")
    local imgFile = pformat("%s.bin", node.chipid())
    local started = false

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
            end
            local ok, err = pcall(otaupgrade.write, data)
            if not ok then
                callback(pformat("Error writing NodeMCU update data: %s", err))
                return
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

return Updater
