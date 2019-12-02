local client = require("mqtt.service"):subclient("espore/" .. firmware.name)
local wifi = require("wifi.manager")
local pkg = require("core.pkg")
local pformat = require("core.stringutil").pformat

return function(config)
    pkg.unload("tools.monitor")

    tmr.create():alarm(
        (config.period or 60) * 1000,
        tmr.ALARM_AUTO,
        function()
            client:publish("sys/uptime", pformat("%d", math.floor(node.uptime() / 1000000)))
            client:publish("sys/free", pformat("%d", node.heap()))
        end
    )

    client:runOnConnect(
        function(reconnect)
            client:publish("sys/version", firmware.version, 0, true)
            client:publish("sys/chipid", node.chipid(), 0, true)
            client:publish("sys/wifi/ip", wifi.info.ip, 0, true)
            client:publish("sys/wifi/mac", wifi.info.mac, 0, true)
            client:publish("sys/wifi/ssid", wifi.info.ssid, 0, true)
            client:publish("sys/wifi/gw", wifi.info.gw, 0, true)
            client:publish("sys/wifi/netmask", wifi.info.netmask, 0, true)
        end
    )
end
