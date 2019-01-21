print("Waiting. Set main to nil to stop")
local siteconfig
local deviceconfig
local Event

BootEvents = {}

local function wifiMain(info)
    print("Wifi Connected: " .. info.ip)
    --startTelnet = require("telnetserver")
    --startTelnet(config.TELNET_PORT, config.TELNET_MOTD)
end

function main()
    require("polyfill")
    Event = require("event")
    local json = require("json")
    BootEvents.main = Event:new()

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

    BootEvents.main:fire()
    BootEvents.main = nil

    local wifiManager = require("wifimanager")
    wifiManager.start()
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
