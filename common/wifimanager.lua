WifiManager = {}
WifiManager.startWifi = function (ssid,password, onConnect)
    wifi.setmode(wifi.STATION)
    --wifi.mode(wifi.STATION)
    local station_cfg={}
    station_cfg.ssid=ssid
    station_cfg.pwd=password
    station_cfg.save=false
    station_cfg.auto=true   
    wifi.sta.config(station_cfg)
    wifi.sta.autoconnect(1)
    wifi.sta.connect()
    timer=tmr.create()
    timer:alarm(1000, tmr.ALARM_AUTO, function() 
        if wifi.sta.getip()==nil then
            print("Connect AP, Waiting...") 
        else
            timer:unregister()
            if onConnect ~= nil then
                onConnect()
            end
        end
    end)
end
return WifiManager
