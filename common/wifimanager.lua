WifiManager = {}
WifiManager.startWifi = function (ssid,password, onConnect)
    wifi.mode(wifi.STATION)
    wifi.start()
    local station_cfg={}
    station_cfg.ssid=ssid
    station_cfg.pwd=password
    station_cfg.save=false
    station_cfg.auto=true   
    wifi.sta.config(station_cfg)

    wifi.sta.on("got_ip", function(ev, info) 
        WifiManager.info = info
        onConnect(info)
    end)
    
    wifi.sta.connect()
    
end
return WifiManager
