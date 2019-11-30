local client = require("mqtt.service")
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
end
