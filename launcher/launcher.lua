-- datafile: app-config.json
-- datafile: site-app-config.json
local log = require("core.log"):new("launcher")
local defer = require("core.defer")
local infoMonitor = require("tools.info")
local Launcher = {apps = {}}

infoMonitor.subscribe("apps", function()
    local appList = {}
    for _, app in ipairs(Launcher.apps) do
        table.insert(appList, {
            name = app.name,
            description = app.description,
            module = app.module
        })
    end
    return {list = appList}
end)

function launchApp(App, appInfo)
    log:info("Launching %s ...", appInfo.name)
    local ok, instance = pcall(App.new, App)
    if not ok then
        log:error("Error instantiating %s: %s", appInfo.name, instance)
        return
    end
    instance.name = appInfo.name
    instance.description = appInfo.description
    instance.module = appInfo.module
    local ok, err = pcall(instance.init, instance, appInfo.config)
    if not ok then
        log:error("Error initializing %s: %s", appInfo.name, err)
        return
    end
    table.insert(Launcher.apps, instance)
end

function launch(appInfo)
    local err
    local ok, App = pcall(require, appInfo.module)
    if ok then
        ok, err = pcall(launchApp, App, appInfo)
        if not ok then
            log:error("Error launching %s: %s", appInfo.module, err)
        end
    else
        log:error("Cannot load module %s: %s", appInfo.module, App)
    end
end

function main()
    local json = require("core.json")
    local configs = {
        json.read("app-config.json"), json.read("site-app-config.json")
    }
    log:info("Launcher module loaded")
    local i = 0
    for _, appconfig in pairs(configs) do
        if appconfig ~= nil then
            for _, appInfo in pairs(appconfig) do
                defer(function() launch(appInfo) end)
                i = i + 1
            end
        end
    end
    defer(function()
        if i == 0 then
            log:warning(
                "No applications were launched. Does app-config.json or site-app-config.json exist?")
        else
            log:info("%d application(s) launched", i)
        end
    end)
    defer(function() infoMonitor.update() end)
end

main()

return Launcher
