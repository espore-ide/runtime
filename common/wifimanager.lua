local Event = require("event")
local WifiManager = {}

WifiManager.OnConnect = Event:new()

WifiManager.start = function(ssid, password)
    wifi.mode(wifi.STATION)
    wifi.start()
    local station_cfg = {}
    station_cfg.ssid = ssid
    station_cfg.pwd = password
    station_cfg.save = false
    station_cfg.auto = true
    wifi.sta.config(station_cfg)

    wifi.sta.on(
        "got_ip",
        function(ev, info)
            WifiManager.OnConnect:fire(info, WifiManager.info ~= nil)
            WifiManager.info = info
        end
    )

    wifi.sta.connect()
end
return WifiManager
