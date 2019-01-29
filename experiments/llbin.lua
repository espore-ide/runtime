function upbin(fname, size)
    local remaining = size
    local f = file.open(fname, "w+")
    local h = crypto.new_hash("sha1")
    local nextChunk
    print("xxx")
    
    local function writer(data)
        f:write(data)
        h:update(data)
        remaining = remaining - #data
        nextChunk()
    end

    nextChunk = function()
        print(remaining)
        if remaining <= 0 then
            f:close()
            uart.on("data")
            local hash=encoder.toHex(h:finalize())
            print(hash)
            return
        end

        local chunkSize = remaining
        if chunkSize > 255 then
            chunkSize = 255
        end
        uart.on("data", chunkSize, writer, 0)
    end

    nextChunk()
end
