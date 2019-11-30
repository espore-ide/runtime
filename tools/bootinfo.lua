local client = require("mqtt.service")
local wifi = require("wifi.manager")
local pkg = require("core.pkg")

return function(config)
    pkg.unload("tools.bootinfo")
    local onconnect
    onconnect = function(reconnect)
        client.OnConnect:unlisten(onconnect)
        --        client:publish("sys/wifi", sjson.encode(wifi.info), 0, true)
        client:publish("sys/wifi/ip", wifi.info.ip, 0, true)
        client:publish("sys/wifi/mac", wifi.info.mac, 0, true)
        client:publish("sys/wifi/ssid", wifi.info.ssid, 0, true)
        client:publish("sys/wifi/gw", wifi.info.gw, 0, true)
        client:publish("sys/wifi/netmask", wifi.info.netmask, 0, true)
    end

    client.OnConnect:listen(onconnect)
end
