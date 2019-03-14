
wifi.sta.on("got_ip", function(ev, info)
    wifi.sta.on("got_ip", nil)
    print("NodeMCU IP config:", info.ip, "netmask", info.netmask, "gw", info.gw)
end)

wifi.mode(wifi.STATION)
wifi.start()
station_cfg={}
--station_cfg.ssid="MonkeyWorkshop 2.4G"
--station_cfg.pwd="peleorens1979"
station_cfg.ssid="Monkey WiFi"
station_cfg.pwd="peleorens1979"
--station_cfg.ssid="EPiC WiFi"
--station_cfg.pwd="gandalf999!"


wifi.sta.config(station_cfg)
