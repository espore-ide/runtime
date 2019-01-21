local Updater = {}
local pformat = require("stringutil").pformat
local json = require("json")
local datafiles = require("datafiles")

local CONFIG_FILE = "updater-config.json"
local etagFile = "fw-etag.txt"
local fmFile = "fw-files.json"

datafiles.add(CONFIG_FILE, etagFile, fmFile)

local config = json.read(CONFIG_FILE)
if config == nil then
    error("Cannot read " .. CONFIG_FILE)
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
    local fetag = file.open(etagFile, "r")
    local etag = ""
    if fetag then
        etag = fetag:readline()
        fetag:close()
    end
    return etag
end

local function writeEtag(etag)
    local fetag = file.open(etagFile, "w")
    if fetag then
        fetag:write(etag)
        fetag:close()
    end
end

local function toLocalFile(fileName)
    local localFile
    _, localFile = fileName:match("(.*/)(.*)")
    return localFile
end

Updater.check = function(callback)
    local fm
    local etag = readEtag()
    local url = string.format("http://%s:%d%s/%s.json", config.host, config.port, config.basePath, node.chipid())
    local headers = {
        ["If-None-Match"] = etag
    }
    local function downloadUpdates(dlist)
        local i = 1
        local Downloader = require("downloader")
        local function cancel(err)
            for _, entry in ipairs(dlist) do
                if entry.tmpfile ~= nil then
                    file.remove(entry.tmpfile)
                end
            end
            callback(err)
        end
        local function finishOff()
            for _, entry in ipairs(dlist) do
                file.remove(entry.localfile)
                file.rename(entry.tmpfile, entry.localfile)
            end
            writeEtag(etag)
            json.write(fmFile, fm)
            local list = file.list()
            for fileName, _ in pairs(fm.files) do
                list[toLocalFile(fileName)] = nil
            end
            for _, fileName in ipairs(datafiles) do
                list[fileName] = nil
            end
            for fileName, _ in pairs(list) do
                file.remove(fileName)
            end
            callback(#dlist)
        end
        local function processNext()
            if i == #dlist + 1 then
                finishOff()
                return
            end
            local entry = dlist[i]
            i = i + 1
            entry.localfile = toLocalFile(entry.file)
            entry.tmpfile = pformat("tmp-%s", entry.localfile)
            Downloader.download(
                config.host,
                config.port,
                config.basePath .. entry.file,
                entry.tmpfile,
                function(err, size, hash)
                    if err ~= nil then
                        cancel(pformat("Error downloading %s: %s", entry.file, err))
                        return
                    end
                    if hash ~= entry.hash then
                        cancel(pformat("Hash mismatch in %s. Expected %s, got %s", entry.file, entry.hash, hash))
                        return
                    end
                    processNext()
                end
            )
        end

        processNext()
    end
    http.get(
        url,
        {headers = headers},
        function(code, body, headers)
            if code == 304 then
                callback(0)
            else
                if code == 200 then
                    etag = headers["etag"]
                    fm = json.parse(body)
                    body = nil
                    if fm == nil or not fm.files then
                        callback("Incorrect json firmware format")
                        return
                    end
                    local lfm = json.read(fmFile)
                    if lfm == nil or not lfm.files then
                        lfm = {files = {}}
                    end
                    local dlist = {}
                    for file, hash in pairs(fm.files) do
                        if hash ~= lfm.files[file] then
                            dlist[#dlist + 1] = {file = file, hash = hash}
                        end
                    end
                    lfm = nil
                    downloadUpdates(dlist)
                else
                    callback(pformat("Error downloading fw: %d", code))
                end
            end
        end
    )
end

return Updater
