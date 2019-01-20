
local Downloader = require("downloader")

collectgarbage()
print("begin", node.heap())

Downloader.download("192.168.43.224", 8080, "/esp32/sha1.lua", "test.txt", function(err, len , hash)
    print(err, len, hash)
    Downloader=nil
    collectgarbage()
    print("end", node.heap())
  
end)