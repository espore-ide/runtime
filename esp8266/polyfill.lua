wifi.mode = wifi.setmode
wifi.start = function () end

wifi.sta.on = function (event, callback)
    if event=="got_ip" then
        local timer=tmr.create()
        timer:alarm(1000, tmr.ALARM_AUTO, function()
            local ip,netmask,gw =  wifi.sta.getip()
            if ip==nil then
                print("Connect AP, Waiting...") 
            else
                timer:unregister()
                timer=nil
                if callback ~= nil then
                    callback(event,{ip=ip, netmask=netmask, gw=gw})
                end
            end
        end)
    end
end

http._get = http.get
http.get = function (url, options, callback)
    local headers =""
    if options and options.headers then
        for h,v in pairs(options.headers) do
            headers = headers .. string.format("%s: %s\r\n", h,v)
        end
    end
    return http._get(url, headers, callback)
end
