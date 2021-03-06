--
local HttpServer = require("net.http.server")
local serveFile = require("net.http.static")
local serveJSON = require("net.http.json")
local wifi =
    require("wifi.manager").OnConnect:listen(
    function()
        server =
            HttpServer(
            {
                port = 80,
                routes = {
                    {
                        pattern = "/vars",
                        handler = function(r, matches)
                            return function(conn, req, args)
                                conn:sendHeader(200)
                                for k, v in pairs(_G) do
                                    conn:send(tostring(k) .. " = " .. tostring(v) .. "\r\n")
                                end
                            end
                        end
                    },
                    {
                        pattern = "/json",
                        handler = function(r, matches)
                            return serveJSON(file.list())
                        end
                    },
                    {
                        pattern = "/content/(.*)",
                        handler = function(r, matches)
                            return serveFile(matches[1])
                        end
                    },
                    {
                        pattern = ".*",
                        handler = function(r, matches)
                            return function(conn, req, args)
                                conn:sendHeader(200, "text/html")
                                conn:send("<html><head></head><body>" .. matches[1] .. "</body></html>\r\n")
                            end
                        end
                    }
                }
            }
        )
        print("Started server")
    end
)
