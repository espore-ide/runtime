local Updater = {}
local pformat = require("pformat")

function parseJSON(data)
    local ok, obj = pcall(sjson.decode,data)
    if not ok then
        obj=nil
    end
    return obj
end

function readJSON(fileName)
    if file.open(fileName,"r") then
        local data=file.read()
        file.close()
        return parseJSON(data)
    end
end

function writeJSON(fileName, obj)
    if file.open(fileName, "w") then
        local data = sjson.encode(obj)
        file.write(data)
        file.close()
    end
end

local etagFile = "fw-etag.txt"
function readEtag()
   local fetag = file.open(etagFile,"r")
   local etag=""
    if fetag then
        etag=fetag:readline()
        fetag:close()
    end
    return etag
end

function writeEtag(etag)
    local fetag=file.open(etagFile,"w")
    if fetag then
        fetag:write(etag)
        fetag:close()
    end
end

Updater.check = function(host, port, basePath, callback)
    local fm
    local fmFile="fw-files.json"
    local etag = readEtag()
    local url=string.format("http://%s:%d%s/%s.json",host,port,basePath, node.chipid())
    local headers = {
        ["If-None-Match"] = etag
    }
    http.get(url,{headers=headers}, function (code, body, headers)
            if code == 304 then
                callback()
            else
                if code == 200 then
                    etag = headers["etag"]
                    fm = parseJSON(body)
                    body=nil
                    local lfm = readJSON(fmFile)
                    if lfm == nil or not lfm.files then
                        lfm = {files={}}
                    end
                    if not fm.files then
                        callback("Incorrect format")
                        return
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
                    callback("Error downloading fw")
                end
            end
        end)

    function downloadUpdates(dlist)
        for j,e in pairs(dlist) do
            print(j,e)
        end
 
        local i=1
        local Downloader = require("downloader")
        function cancel(err)
            for _, entry in ipairs(dlist) do
                if entry.tmpfile ~=nil then
                    file.remove(entry.tmpfile)
                end
            end
            callback(err)
        end
        function finishOff()
            for _, entry in ipairs(dlist) do
                file.remove(entry.localfile)
                file.rename(entry.tmpfile, entry.localfile)
            end
            writeEtag(etag)
            writeJSON(fmFile, fm)
            callback()   
        end
        function processNext()
            if i == #dlist+1 then
                finishOff()
                return
            end
            entry=dlist[i]
            i=i+1
            _, entry.localfile=entry.file:match("(.*/)(.*)")
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
end

return Updater
