local mqtt = require("mqtt.service"):subclient("espore/" .. firmware.name)
local wifi = require("wifi.manager")
local pkg = require("core.pkg")
local pformat = require("core.stringutil").pformat

local UPDATE_FAIL_FILE = "update.img.fail" -- see init.lua
local trialVersion = true

function reportVersion()
    if trialVersion then trialVersion = file.exists(UPDATE_FAIL_FILE) end
    local version = firmware.version
    if trialVersion then version = version .. "-trial" end
    mqtt:publish("sys/version", version, 0, true)
end

function reportStats()
    if trialVersion then reportVersion() end
    mqtt:publish("sys/uptime",
                 pformat("%d", math.floor(node.uptime() / 1000000)))
    mqtt:publish("sys/free", pformat("%d", node.heap()))
end

return function(config)
    pkg.unload("tools.monitor")

    tmr.create():alarm((config.period or 60) * 1000, tmr.ALARM_AUTO, reportStats)

    mqtt:runOnConnect(function(reconnect)
        reportStats()
        mqtt:publish("sys/chipid", node.chipid(), 0, true)
        mqtt:publish("sys/wifi/ip", wifi.info.ip, 0, true)
        mqtt:publish("sys/wifi/mac", wifi.info.mac, 0, true)
        mqtt:publish("sys/wifi/ssid", wifi.info.ssid, 0, true)
        mqtt:publish("sys/wifi/gw", wifi.info.gw, 0, true)
        mqtt:publish("sys/wifi/netmask", wifi.info.netmask, 0, true)
    end)
end
