ESP8266 = true

local wifi_ = wifi
wifi = {}
wifi.mode = wifi_.setmode
wifi.STATION = wifi_.STATION
wifi.sta = {}
for k, v in pairs(wifi_.sta) do
    wifi.sta[k] = v
end
wifi.start = function()
end

local connected_cb, disconnected_cb, got_ip_cb

wifi.sta.on = function(evt, callback)
    if evt == "connected" then
        connected_cb = callback
    else
        if evt == "disconnected" then
            disconnected_cb = callback
        else
            if evt == "got_ip" then
                got_ip_cb = callback
            else
                error("Error. Unknown event ", evt)
            end
        end
    end
end

wifi.sta.config_ = wifi.sta.config

wifi.sta.config = function(cfg)
    local config = {}
    for k, v in pairs(cfg) do
        config[k] = v
    end
    config.connect_cb = connected_cb
    config.disconnect_cb = disconnected_cb
    config.got_ip_cb = got_ip_cb

    return wifi.sta.config_(config)
end

local http_ = http
http = {}
http.get = function(url, options, callback)
    local headers = ""
    if options and options.headers then
        for h, v in pairs(options.headers) do
            headers = headers .. string.format("%s: %s\r\n", h, v)
        end
    end
    return http_.get(url, headers, callback)
end
