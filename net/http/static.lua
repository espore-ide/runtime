-- httpserver-static.lua
-- Part of nodemcu-httpserver, handles sending static files to client.
-- Author: Marcos Kirsch
local ext2mime = require("net.http.mime")
local errorHandler = require("net.http.error")

return function(filename, mimeType, isGzipped)
   return function(connection, req, args)
      local f = file.open(filename)
      if f == nil then
         errorHandler(404, "Cannot find " .. filename)(connection, req, args)
         return
      end
      mimeType = mimeType or ext2mime(filename:match("^.+%.(.+)$"))
      connection:sendHeader(200, mimeType, isGzipped)
      repeat
         local chunk = f:read(1024)
         if chunk ~= nil then
            connection:send(chunk)
         else
            break
         end
      until false
      f:close()
      f = nil
      collectgarbage()
   end
end
