print("\n\n\nHomeNode starting ...")

function start()
    local log = require("core.log"):new("init")
    log:info("starting up")
    local Event = require("core.event")
    local json = require("core.json")
    local defer = require("core.defer")

    local function loadModules(modules)
        if not modules then return end
        for _, module in ipairs(modules) do
            defer(function()
                if module.autostart then
                    log:info("Loading %s", module.name)
                    local ok, modFunc = pcall(require, module.name)
                    if not ok then
                        log:error("Error loading module %s: %s", module.name,
                                  modFunc)
                    end
                    if type(modFunc) == "table" then
                        if type(modFunc.init) == "function" then
                            modFunc = modFunc.init
                        end
                    end
                    if type(modFunc) == "function" then
                        ok, err = pcall(modFunc, module.config)
                        if not ok then
                            log:error("Error initializing module %s: %s",
                                      module.name, err)
                        end
                    end
                end
            end)
        end
    end

    OnLoad = Event:new()

    firmware = json.read("firmware.json")
    local modules = json.read("modules.json")
    if firmware then
        local ok, err = pcall(loadModules, modules)
        if not ok then log:error("Error loading modules: %s", err) end
    end

    OnLoad:fire()

    OnLoad = nil
    start = nil
end

start()
start = nil
