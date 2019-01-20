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
    BootEvents.main = Event:new()

    siteconfig = require("site-config")
    deviceconfig = require("device-config")

    if siteconfig.MODULES then
        for _, moduleName in ipairs(siteconfig.MODULES) do
            require(moduleName)
        end
    end

    if deviceconfig.MODULES then
        for _, moduleName in ipairs(deviceconfig.MODULES) do
            require(moduleName)
        end
    end

    BootEvents.main:fire()
    BootEvents.main = nil

    local wifiManager = require("wifimanager")
    wifiManager.OnConnect:listen(wifiMain)
    wifiManager.start(siteconfig.WIFI_SSID, siteconfig.WIFI_PASSWORD)
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
