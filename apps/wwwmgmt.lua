local serveFile = require("net.http.static")
local serveError = require("net.http.error")
local serveJSON = require("net.http.json")
local HttpServer = require("net.http.server")
local Launcher = require("launcher.launcher")
local WifiManager = require("wifi.manager")
local json = require("core.json")

local App = {}

local WWW_PATH = "www"
local routes = {
    {
        pattern = "/nodeinfo",
        handler = function(r, matches)
            return serveJSON(
                {
                    chipid = node.chipid(),
                    firmware = firmware,
                    heap = node.heap(),
                    connectionInfo = WifiManager.info
                }
            )
        end
    },
    {
        pattern = "^/apps$",
        handler = function(r, matches)
            local apps = {}
            for appId, app in ipairs(Launcher.apps) do
                local appInfo = {
                    id = appId,
                    name = app.name,
                    actions = {},
                    dashboard = {}
                }
                local ui = app.ui and app:ui()
                if ui ~= nil then
                    for i, action in ipairs(ui.actions) do
                        local a = json.clean(action)
                        a.id = i
                        table.insert(appInfo.actions, a)
                    end

                    for i, dItem in ipairs(ui.dashboard) do
                        local d = json.clean(dItem)
                        d.value = dItem.value()
                        d.id = i
                        table.insert(appInfo.dashboard, d)
                    end
                end
                table.insert(apps, appInfo)
            end

            return serveJSON(apps)
        end
    },
    {
        pattern = "/apps/(%d*)/action/(%d*)",
        methods = {"POST"},
        handler = function(r, matches)
            local app = Launcher.apps[tonumber(matches[1])]
            if not app then
                return serveError(404, "Application " .. matches[1] .. " not found")
            end
            local ui = app.ui and app:ui()
            if ui == nil then
                return serveError(404, "Application " .. matches[1] .. " does not define a UI")
            end
            local action = ui.actions[tonumber(matches[2])]
            if not action or type(action.action) ~= "function" then
                return serveError(404, "Action " .. matches[2] .. "not found")
            end
            local ok, err = pcall(action.action)
            if not ok then
                return serveError(404, "Error invoking action: " .. err)
            end

            return serveJSON({result = "OK"})
        end
    },
    {
        pattern = "/files",
        handler = function(r, matches)
            return serveJSON(file.list())
        end
    },
    {
        pattern = "^(.*/)$",
        handler = function(r, matches)
            return serveFile(WWW_PATH .. matches[1] .. "index.html")
        end
    },
    {
        pattern = ".*",
        handler = function(r, matches)
            return serveFile(WWW_PATH .. matches[1])
        end
    }
}

function App:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function App:init(config)
    config = config or {}
    self.s = HttpServer({port = config.port, routes = routes})
    require("core.log"):new("httpserver/" .. self.name):info("HTTP server started")
end

function App:terminate()
    self.s:close()
end

return App
--
