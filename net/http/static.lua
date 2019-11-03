-- httpserver-static.lua
-- Part of nodemcu-httpserver, handles sending static files to client.
-- Author: Marcos Kirsch
local sendHeader = require("net.http.header")
local ext2mime = require("net.http.mime")
return function(connection, req, args)
   sendHeader(connection, 200, ext2mime(args.ext), args.isGzipped)
   -- Send file in little chunks
   local bytesRemaining = file.list()[args.file]
   -- Chunks larger than 1024 don't work.
   -- https://github.com/nodemcu/nodemcu-firmware/issues/1075
   local chunkSize = 1024
   local fileHandle = file.open(args.file)
   while bytesRemaining > 0 do
      local bytesToRead = math.min(bytesRemaining, chunkSize)
      local chunk = fileHandle:read(bytesToRead)
      connection:send(chunk)
      bytesRemaining = bytesRemaining - #chunk
      --print(args.file .. ": Sent "..#chunk.. " bytes, " .. bytesRemaining .. " to go.")
      chunk = nil
      collectgarbage()
   end
   -- print("Finished sending: ", args.file)
   fileHandle:close()
   fileHandle = nil
   collectgarbage()
end
