Updater = {}

Updater.check = function(basePath, callback)
    local etag = ""
    if file.open("fw-etag.txt","r") then
        etag=file.readline()
        file.close()
    end
    http.get(basePath .. "/" .. node.chipid() .. ".json",
        'If-None-Match: "' .. etag ..'"\r\n', function (code, body, headers)
            if code == 304 then
                callback()
            else
                print(headers["etag"])
            end
        end)
end

return Updater