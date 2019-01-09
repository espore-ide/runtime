crypto = {}

local sha1lib = require("sha1") 
crypto.new_hash = function(algo)
    if algo ~= "SHA1" then
        error("Unsupported hash algorithm " .. algo)
    end
    return sha1lib:new()
end

crypto.toHex = function (bytes)
    local out = {}
    for i=1,#bytes do
        out[i] = string.format("%02x", string.byte(bytes, i))
    end
    return table.concat(out)
end
