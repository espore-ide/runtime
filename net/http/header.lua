-- httpserver-header.lua
-- Part of nodemcu-httpserver, knows how to send an HTTP header.
-- Author: Marcos Kirsch

local codez = {
   [200] = "OK",
   [400] = "Bad Request",
   [401] = "Unauthorized",
   [404] = "Not Found",
   [405] = "Method Not Allowed",
   [500] = "Internal Server Error",
   [501] = "Not Implemented"
}

return function(connection, code, mimeType, isGzipped, extraHeaders)
   local statusString = codez[code] or codez[501]
   mimeType = mimeType or "text/plain"

   connection:send(
      "HTTP/1.0 " ..
         code .. " " .. statusString .. "\r\nServer: nodemcu-httpserver\r\nContent-Type: " .. mimeType .. "\r\n"
   )
   if isGzipped then
      connection:send("Cache-Control: private, max-age=2592000\r\nContent-Encoding: gzip\r\n")
   end
   if (extraHeaders) then
      for i, extraHeader in ipairs(extraHeaders) do
         connection:send(extraHeader .. "\r\n")
      end
   end

   connection:send("Connection: close\r\n\r\n")
   return statusString
end
