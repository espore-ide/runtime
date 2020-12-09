-- datafile: wifi-last.json
local Event = require("core.event")
local json = require("core.json")
local infoMonitor = require("tools.info")

local WifiManager = {}

local WIFI_CONFIG_FILE = "wifi-config.json"
local WIFI_LAST = "wifi-last.json"

local log = require("core.log"):new("wifi.manager")

local networks
local currentNetwork = 0
local reconnect = false

WifiManager.OnConnect = Event:new()
WifiManager.OnAPDisconnect = Event:new()

local function onconnect(info, reconnect)
    local cfg = networks[currentNetwork]
    table.remove(networks, currentNetwork)
    table.insert(networks, 1, cfg)
    json.write(WIFI_LAST, cfg)
end

local function connectNext()
    if #networks == 0 then
        log:error("No networks defined in configuration. Cannot connect")
        return
    end
    currentNetwork = currentNetwork + 1
    if currentNetwork > #networks then currentNetwork = 1 end
    local cfg = networks[currentNetwork]

    log:info("trying to connect to " .. cfg.ssid)
    wifi.sta.config(cfg)
    wifi.sta.connect()
end

WifiManager.start = function()
    wifi.sta.on("got_ip", function(evt, info)
        local cfg = networks[currentNetwork]
        log:info("Connected to %s. IP=%s", cfg.ssid, info.ip)
        WifiManager.OnConnect:fire(info, reconnect)
        reconnect = true
        info.ssid = cfg.ssid
        info.mac = wifi.sta.getmac()
        WifiManager.info = info
    end)
    wifi.sta.on("disconnected",
                function(evt, info) WifiManager.OnAPDisconnect:fire(info) end)
    WifiManager.OnConnect:listen(onconnect)

    wifi.mode(wifi.STATION)

    local wifiCfg = json.read(WIFI_CONFIG_FILE)
    if wifiCfg == nil then
        log:error("cannot read " .. WIFI_CONFIG_FILE)
        return
    end
    networks = wifiCfg.networks
    local last = json.read(WIFI_LAST)
    if last ~= nil then
        for i, cfg in ipairs(networks) do
            if cfg.ssid == last.ssid then
                table.remove(networks, i)
                break
            end
        end
        table.insert(networks, 1, last)
    end
    WifiManager.OnAPDisconnect:listen(function()
        log:warning("AP disconnected")
        connectNext()
    end)

    wifi.sta.on("start", function()
        wifi.sta.sethostname(firmware.name:gsub("[^%w-]", ""))
        connectNext()
    end)
    wifi.start()
end
tmr.create():alarm(100, tmr.ALARM_SINGLE, function() WifiManager.start() end)

infoMonitor.subscribe("wifi", function() return WifiManager.info end)

return WifiManager
