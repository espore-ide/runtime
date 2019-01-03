print("Waiting. Set main to nil to stop")

function main()
    config = require("config")
    wifiManager = require("wifimanager")
    wifiManager.startWifi(config.WIFI_SSID, config.WIFI_PASSWORD, wifiMain)

end

function wifiMain()
    print("Wifi Connected: " .. wifi.sta.getip())
    --startTelnet = require("telnetserver")
    --startTelnet(config.TELNET_PORT, config.TELNET_MOTD)
end

tmr.create():alarm(3000, tmr.ALARM_SINGLE, function() if main ~= nil then main() end end)
