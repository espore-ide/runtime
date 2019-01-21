ESP8266 = true
wifi.mode = wifi.setmode
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
    local config
    for k, v in pairs(cfg) do
        config[k] = v
    end
    config.connected_cb = connected_cb
    config.disconnected_cb = disconnected_cb
    config.got_ip_cb = got_ip_cb

    return wifi.sta.config_(config)
end

http._get = http.get
http.get = function(url, options, callback)
    local headers = ""
    if options and options.headers then
        for h, v in pairs(options.headers) do
            headers = headers .. string.format("%s: %s\r\n", h, v)
        end
    end
    return http._get(url, headers, callback)
end
