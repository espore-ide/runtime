print("Waiting. Set main to nil to stop")

function main()
    require("polyfill")
    local Event = require("event")
    local json = require("json")
    OnLoad = Event:new()

    local firmware = json.read("firmware.json")
    if firmware and firmware.modules then
        for _, moduleName in ipairs(firmware.modules) do
            print("loading", moduleName)
            require(moduleName)
        end
    end

    local siteconfig = json.read("site-config.json")
    if siteconfig and siteconfig.modules then
        for _, moduleName in ipairs(siteconfig.modules) do
            print("loading", moduleName)
            require(moduleName)
        end
    end

    OnLoad:fire()
    OnLoad = nil
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
