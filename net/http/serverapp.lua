local App = {}

function App:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function App:init(config)
    config = config or {}
    local HttpServer = require("net.http.server")
    require("core.log"):new("httpserver/" .. self.name):info("HTTP server started")
    self.s = HttpServer({port = config.port})
end

function App:terminate()
    self.s:close()
end

return App
