local Updater = {}
local pformat = require("pformat")

Updater.ignoreList={}
local etagFile = "fw-etag.txt"
local fmFile="fw-files.json"

Updater.ignore = function(fileName)
    Updater.ignoreList[fileName]=true
end

Updater.ignore(etagFile)
Updater.ignore(fmFile)

local function parseJSON(data)
    local ok, obj = pcall(sjson.decode,data)
    if not ok then
        obj=nil
    end
    return obj
end

local function readJSON(fileName)
    local f = file.open(fileName,"r") 
    if not f then
        return nil
    end
    local data=""
    while true do
        local chunk = f:read()
        if chunk ~= nil then
            data = data .. chunk
        else
            break
        end
    end
    f:close()
    return parseJSON(data)
end

local function writeJSON(fileName, obj)
    local f = file.open(fileName, "w")
    if f then
        local data = sjson.encode(obj)
        f:write(data)
        f:close()
    end
end

local function readEtag()
   local fetag = file.open(etagFile,"r")
   local etag=""
    if fetag then
        etag=fetag:readline()
        fetag:close()
    end
    return etag
end

local function writeEtag(etag)
    local fetag=file.open(etagFile,"w")
    if fetag then
        fetag:write(etag)
        fetag:close()
    end
end

local function toLocalFile(fileName)
    local localFile
    _, localFile=fileName:match("(.*/)(.*)")
    return localFile
end

Updater.check = function(host, port, basePath, callback)
    local fm
    local etag = readEtag()
    local url=string.format("http://%s:%d%s/%s.json",host,port,basePath, node.chipid())
    local headers = {
        ["If-None-Match"] = etag
    }
    local function downloadUpdates(dlist)
        local i=1
        local Downloader = require("downloader")
        local function cancel(err)
            for _, entry in ipairs(dlist) do
                if entry.tmpfile ~=nil then
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
            writeJSON(fmFile, fm)
            local list = file.list()
            for fileName, _ in pairs(fm.files) do
                list[toLocalFile(fileName)]=nil
            end
            for fileName, _ in pairs(Updater.ignoreList) do
                list[fileName]=nil
            end
            for fileName, _ in pairs(list) do
                file.remove(fileName)
            end
            callback(#dlist)   
        end
        local function processNext()
            if i == #dlist+1 then
                finishOff()
                return
            end
            local entry=dlist[i]
            i=i+1
            entry.localfile=toLocalFile(entry.file)
            entry.tmpfile=pformat("tmp-%s",entry.localfile)
            Downloader.download(host, port, basePath .. entry.file, entry.tmpfile, function (err, size, hash)
                if err ~= nil then
                    cancel(pformat("Error downloading %s: %s", entry.file, err))
                    return
                end
                if hash ~= entry.hash then
                    cancel(pformat("Hash mismatch in %s. Expected %s, got %s", entry.file, entry.hash, hash))
                    return
                end
                processNext()
            end)
        end

        processNext()
    end
    http.get(url,{headers=headers}, function (code, body, headers)
        if code == 304 then
            callback(0)
        else
            if code == 200 then
                etag = headers["etag"]
                fm = parseJSON(body)
                body=nil
                if fm == nil or not fm.files then
                    callback("Incorrect json firmware format")
                    return
                end
                local lfm = readJSON(fmFile)
                if lfm == nil or not lfm.files then
                    lfm = {files={}}
                end
                local dlist = {}
                for file,hash in pairs(fm.files) do
                    if hash ~= lfm.files[file] then
                        dlist[#dlist+1]={file=file, hash=hash}
                    end
                end
                lfm=nil
                downloadUpdates(dlist)
            else
                callback(pformat("Error downloading fw: %d", code))
            end
        end
    end)
end

return Updater
