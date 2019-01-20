
function parseJSON(data)
    local ok, obj = pcall(sjson.decode,data)
    if not ok then
        obj=nil
    end
    return obj
end


local json='{"name":"device1","files":{"/device1/firmware.json":"f0edd9c23d3804d7d5732767271de874ca8ae171","/device1/somefile.lua":"f42fedc5af05aba70f2f1e726b7d3b99f7d4a19c","/esp32/polyfill.lua":"000fae3fe814aca08bd001446a58bfeb17260280","/esp32/sha1.lua":"256bc191692eddd287075e886cf19318cbed90eb","/testfw/testfwfile.lua":"094e94e9506f195a32bae07aab0125cfa2f05c43"}}'

local a = parseJSON(json)

local json2 = sjson.encode(a)
print(json2 )

collectgarbage()
print(node.heap())