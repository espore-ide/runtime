print("Waiting. Set main to nil to stop")

function main()
    if node.flashindex then
        pcall(node.flashindex("_init"))
    end
    local log = require("log"):new("init")
    log:info("starting up")
    require("polyfill")
    local Event = require("event")
    local json = require("json")

    local function loadModules(modules)
        if not modules then
            return
        end
        for _, moduleName in ipairs(modules) do
            log:info("Loading %s", moduleName)
            require(moduleName)
        end
    end

    OnLoad = Event:new()

    firmware = json.read("firmware.json")
    if firmware then
        loadModules(firmware.modules)
    end
    local siteconfig = json.read("site-config.json")
    if siteconfig then
        loadModules(siteconfig.modules)
    end
    OnLoad:fire()

    OnLoad = nil
    main = nil
end

tmr.create():alarm(
    3000,
    tmr.ALARM_SINGLE,
    function()
        if main ~= nil then
            main()
        end
    end
)
