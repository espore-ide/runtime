-- datafile: appconfig.json
local function launchApp(App, appInfo)
    local instance = App:new()
    instance.name = appInfo.name
    instance:init(appInfo.config)
end

local function main()
    local json = require("core.json")
    local log = require("core.log"):new("launcher")

    local appconfig = json.read("appconfig.json")

    if appconfig == nil then
        log:error("Cannot read appconfig.json. Launcher aborted.")
        return
    end

    log:info("Launcher module loaded")
    for k, appInfo in pairs(appconfig) do
        local ok, App = pcall(require, appInfo.module)
        if ok then
            ok, err = pcall(launchApp, App, appInfo)
            if not ok then
                log:error("Error launching %s: %s", appInfo.module, err)
            end
        else
            log:error("Cannot load module %s", appInfo.module)
        end
    end
end

main()
