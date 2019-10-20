-- datafile: updater-etag.json
-- datafile: fw-files.json

local Updater = {}
local pformat = require("core.stringutil").pformat
local json = require("core.json")

local CONFIG_FILE = "updater-config.json"
local etagFile = "updater-etag.json"

local config = json.read(CONFIG_FILE)
if config == nil then
    error("Updater: Cannot read " .. CONFIG_FILE)
end

function Updater.unrequire(packageName)
    package.loaded[packageName] = nil
    _G[packageName] = nil
end

function Updater.unloadAll()
    local packages = {}
    for packageName, _ in pairs(package.loaded) do
        packages[#packages] = packageName
    end
    for _, packageName in ipairs(packages) do
        Updater.unrequire(packageName)
    end
end

local function readEtag()
    jetag = json.read(etagFile) or {ETag = ""}
    return jetag.ETag or ""
end

local function writeEtag(etag)
    json.write(etagFile, {ETag = etag})
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
        "update.img",
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
