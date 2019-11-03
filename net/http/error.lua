-- httpserver-error.lua
-- Part of nodemcu-httpserver, handles sending error pages to client.
-- Author: Marcos Kirsch, Gregor Hartmann

local sendHeader = require("net.http.header")

return function(code, errorString)
   return function(connection, req, args)
      local statusString = sendHeader(connection, code, "text/html", false, args.headers)
      connection:send(
         "<html><head><title>" ..
            code ..
               " - " ..
                  statusString ..
                     "</title></head><body><h1>" ..
                        code .. " - " .. statusString .. "</h1><h2>" .. errorString .. "</h2></body></html>\r\n"
      )
   end
end
