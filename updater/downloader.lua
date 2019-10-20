-- import: core
local Downloader = {}
local pformat = require("core.stringutil").pformat

Downloader.timeout = 1000
Downloader.download = function(host, port, path, dstFile, etag, callback)
    local conn = net.createConnection(net.TCP, 0)
    local connected = false
    local hasher
    local f
    local written = 0
    local watchdogWritten = 0
    local watchdogTimer = tmr.create()

    local write = function(data)
        if f == nil then
            f = file.open(dstFile, "w")
            hasher = crypto.new_hash("SHA1")
        end
        f:write(data)
        hasher:update(data)
        written = written + #data
    end

    local finish = function(err, length)
        watchdogTimer:stop()
        watchdogTimer:unregister()
        watchdogTimer = nil

        local hash
        if f ~= nil then
            f:close()
            hash = hasher:finalize()
            hash = encoder.toHex(hash)
            f = nil
            hasher = nil
        end
        if conn ~= nil then
            if connected then
                conn:close()
                connected = false
            end
            conn = nil
            callback(err, length, hash, etag)
        end
        finish = function()
            --just in case some poor soul calls finish()
        end
    end

    watchdogTimer:alarm(
        Downloader.timeout,
        tmr.ALARM_AUTO,
        function()
            if watchdogWritten == written then
                finish("Download timeout", 0)
            end
            watchdogWritten = written
        end
    )

    conn:on(
        "connection",
        function(conn)
            connected = true
            local inm = ""
            if etag ~= nil then
                inm = pformat("If-None-Match: %s\r\n", etag)
            end
            conn:send(pformat("GET %s HTTP/1.1\r\nHost: %s:%d\r\n%sAccept: */*\r\n\r\n", path, host, port, inm))
        end
    )

    local content = ""
    local headerReceived = false
    local contentLength = -1
    conn:on(
        "receive",
        function(conn, data)
            if not headerReceived then
                content = content .. data
                collectgarbage()
                local i, j = string.find(content, "\r\n\r\n")
                if i ~= nil then
                    local header = string.sub(content, 1, i - 1)
                    content = string.sub(content, j + 1)
                    local status = tonumber(string.match(header, "^HTTP/%d.%d (%d+) .-\r\n"))
                    if status ~= 200 then
                        finish(status)
                        return
                    end
                    contentLength = tonumber(string.match(header, "Content--Length: (%d+)\r\n"))
                    if contentLength == nil then
                        finish("Missing Content-Length header")
                        return
                    end
                    etag = string.match(header, "ETag:%s(.*)%s*\r\n")
                    headerReceived = true
                    write(content)
                    content = nil
                else
                    if #content > 1000 then
                        finish("Header too big")
                        return
                    end
                end
            else
                write(data)
            end
            if contentLength ~= -1 and written >= contentLength then
                finish(nil, written)
                return
            end
        end
    )

    conn:on(
        "disconnection",
        function(x, err)
            connected = false
            if err ~= 0 then
                finish("Disconnected/Error connecting " .. err, nil)
            end
        end
    )

    conn:connect(port, host)
end

return Downloader
