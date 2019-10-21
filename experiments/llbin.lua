__espore = {
    echo = function(value)
        local b, d, p, s = uart.getconfig(0)
        uart.setup(0, b, d, p, s, value)
    end,
    start = function()
        __espore.echo(0)
        print("\nREADY")
    end,
    finish = function()
        print("\nBYE")
        __espore.echo(1)
        __espore = nil
    end,
    upload = function(fname, size)
        local remaining = size
        local f = file.open(fname, "w+")
        local h = crypto.new_hash("sha1")
        local nextChunk

        local function writer(data)
            f:write(data)
            h:update(data)
            remaining = remaining - #data
            nextChunk()
        end

        local function nextChunk()
            print(remaining)
            if remaining <= 0 then
                f:close()
                uart.on("data")
                local hash = encoder.toHex(h:finalize())
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
}
__espore.start()
