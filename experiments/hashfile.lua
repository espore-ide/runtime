

function filehash(fileName, algo) 

    local f = file.open(fileName, "r")
    local data
    local hasher = crypto.new_hash(algo)
    repeat
        data = f:read(60000)
        if data ~= nil then
            hasher:update(data)
        print ("Read " .. #data .. " bytes")
        end
    until data == nil

    f:close()
    print(encoder.toHex(hasher:finalize()))
end