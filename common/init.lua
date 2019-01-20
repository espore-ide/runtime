print("Waiting. Set main to nil to stop")
local siteconfig

local function updated()
    print ("begin")
    local deviceconfig = require("device-config")
    print ("device name", deviceconfig.NAME)
end

local function wifiMain(info)
    print("Wifi Connected: " .. info.ip)
    --startTelnet = require("telnetserver")
    --startTelnet(config.TELNET_PORT, config.TELNET_MOTD)
    local updater = require("updater")
    print("Checking for updates...")
    updater.check(siteconfig.UPDATE_HOST, siteconfig.UPDATE_PORT, "", function (result)
        if type(result) == "string" then
            print("Error updating device:", result)
        else
            if result > 0 then
                print(string.format("%d files updated. Restarting in 5 seconds...", result))
                tmr.create():alarm(5000, tmr.ALARM_SINGLE, function()
                    node.restart()
                end)
                return
            else
                print("no updates found")
            end
        end
        updated()
    end)

    
end

function main()
    require("polyfill")
    siteconfig = require("site-config")
    local wifiManager = require("wifimanager")
    wifiManager.startWifi(siteconfig.WIFI_SSID, siteconfig.WIFI_PASSWORD, wifiMain)

end

tmr.create():alarm(3000, tmr.ALARM_SINGLE, function() 
    if main ~= nil then 
        main() 
    end
end)
