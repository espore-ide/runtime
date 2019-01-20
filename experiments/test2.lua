
toHex = function (bytes)
    local out = {}
    for i=1,#bytes do
        out[i] = string.format("%02x", string.byte(bytes, i))
    end
    return table.concat(out)
end

hashobj = crypto.new_hash("sha1")
hashobj:update("hello")
digest = hashobj:finalize()
print(crypto.toHex(digest))

hashobj = crypto.new_hash("SHA256")
hashobj:update("hello")
digest = hashobj:finalize()
print(crypto.toHex(digest))
hashobj = crypto.new_hash("SHA224")
hashobj:update("hello")
digest = hashobj:finalize()
print(crypto.toHex(digest))

hashobj = crypto.new_hash("SHA512")
hashobj:update("hello")
digest = hashobj:finalize()
print(crypto.toHex(digest))

hashobj = crypto.new_hash("SHA384")
hashobj:update("hello")
digest = hashobj:finalize()
print(crypto.toHex(digest))


hashobj = crypto.new_hash("MD5")
hashobj:update("hello")
digest = hashobj:finalize()
print(crypto.toHex(digest))
