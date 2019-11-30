-- datafile: app-config.json
-- datafile: site-app-config.json

local log = require("core.log"):new("launcher")
local Launcher = {apps = {}}

local function launchApp(App, appInfo)
    log:info("Launching %s ...", appInfo.name)
    local ok, instance = pcall(App.new, App)
    if not ok then
        log:error("Error instantiating %s: %s", appInfo.name, instance)
        return
    end
    instance.name = appInfo.name
    instance.description = appInfo.description
    local ok, err = pcall(instance.init, instance, appInfo.config)
    if not ok then
        log:error("Error initializing %s: %s", appInfo.name, err)
        return
    end
    table.insert(Launcher.apps, instance)
end

local function launch(appInfo)
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

local function main()
    local json = require("core.json")
    local configs = {json.read("app-config.json"), json.read("site-app-config.json")}

    log:info("Launcher module loaded")
    local i = 0
    local lnTimer = tmr.create()
    local launchNext =
        coroutine.wrap(
        function()
            for _, appconfig in pairs(configs) do
                if appconfig ~= nil then
                    for _, appInfo in pairs(appconfig) do
                        launch(appInfo)
                        i = i + 1
                        coroutine.yield()
                    end
                end
            end
            if i == 0 then
                log:warning("No applications were launched. Does app-config.json or site-app-config.json exist?")
            else
                log:info("%d application(s) launched", i)
            end
            lnTimer:stop()
            lnTimer:unregister()
        end
    )
    lnTimer:alarm(1000, tmr.ALARM_AUTO, launchNext)
end

tmr.create():alarm(
    100,
    tmr.ALARM_SINGLE,
    function()
        main()
    end
)

return Launcher
