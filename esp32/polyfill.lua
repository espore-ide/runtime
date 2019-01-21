ESP32 = true

--[[ wifi.sta.config_ = wifi.sta.config

wifi.sta.config = function(cfg)
    if cfg.connected_cb then
        wifi.sta.on("connected", cfg.connected_cb)
    end
    if cfg.disconnected_cb then
        wifi.sta.on("disconnected", cfg.disconnected_cb)
    end
    if cfg.got_ip_cb then
        wifi.sta.on("got_ip", cfg.got_ip_cb)
    end
    return wifi.sta.config_(cfg)
end ]]
