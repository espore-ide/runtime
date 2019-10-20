print("\n\n\nHomeNode starting ...")

function start()
    if node.flashindex then
        local lfsFile = node.chipid() .. "-lfs.img"
        if file.exists(lfsFile) then
            print("Found LFS image. Flashing " .. lfsFile .. " ...")
            file.remove("lfs.img")
            file.rename(lfsFile, "lfs.img")
            local err = node.flashreload("lfs.img")
            print("Error flashing LFS image: " .. err)
        end
        pcall(node.flashindex("_init"))
    end
    local log = require("core.log"):new("init")
    log:info("starting up")
    local Event = require("core.event")
    local json = require("core.json")

    local function loadModules(modules)
        if not modules then
            return
        end
        for _, module in ipairs(modules) do
            if module.autostart then
                log:info("Loading %s", module.name)
                local ok, err = pcall(require, module.name)
                if not ok then
                    log:error("Error loading module %s: %s", module.name, err)
                end
            end
        end
    end

    OnLoad = Event:new()

    firmware = json.read("firmware.json")
    if firmware then
        local ok, err = pcall(loadModules, firmware.modules)
        if not ok then
            log:error("Error loading modules: %s", err)
        end
    end

    OnLoad:fire()

    OnLoad = nil
    start = nil
end

start()
