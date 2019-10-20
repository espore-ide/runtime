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
    jetag = json.read(ETAG_FILE) or {ETag = ""}
    return jetag.ETag or ""
end

local function writeEtag(etag)
    json.write(ETAG_FILE, {ETag = etag})
end

Updater.RESULT_NO_UPDATES = 0
Updater.RESULT_NEW_IMAGE = 1

Updater.check = function(callback)
    local fm
    local etag = readEtag()
    local url = string.format("http://%s:%d%s/%s.img", config.host, config.port, config.basePath, node.chipid())
    local downloader = require("updater.downloader")
    local imgFile = pformat("%s.img", node.chipid())
    downloader.download(
        config.host,
        config.port,
        config.basePath .. imgFile,
        IMAGE_FILE,
        etag,
        function(err, length, hash, newEtag)
            if err == 304 then
                callback(Updater.RESULT_NO_UPDATES)
                return
            end
            if err ~= nil then
                callback(err)
                return
            end
            writeEtag(newEtag)
            callback(Updater.RESULT_NEW_IMAGE)
        end
    )
end

return Updater
