local Event = require("event")
local json = require("json")
local datafiles = require("datafiles")

local WifiManager = {}

local WIFI_CONFIG_FILE = "wifi-config.json"
local WIFI_LAST = "wifi-last.json"

datafiles.add(WIFI_CONFIG_FILE, WIFI_LAST)

local function log(msg)
    print("WIFI MANAGER:", msg)
end

local networks
local currentNetwork = 0
local reconnect = false

WifiManager.OnConnect = Event:new()
WifiManager.OnAPDisconnect = Event:new()

wifi.sta.on(
    "got_ip",
    function(evt, info)
        WifiManager.OnConnect:fire(info, reconnect)
        reconnect = true
    end
)
wifi.sta.on(
    "disconnected",
    function(evt, info)
        WifiManager.OnAPDisconnect:fire(info)
    end
)

local function onconnect()
    local cfg = networks[currentNetwork]
    table.remove(networks, currentNetwork)
    table.insert(networks, 1, cfg)
    json.write(WIFI_LAST, cfg)
end
WifiManager.OnConnect:listen(onconnect)

local function connectNext()
    if #networks == 0 then
        error("No networks defined in configuration. Cannot connect")
        return
    end
    currentNetwork = currentNetwork + 1
    if currentNetwork > #networks then
        currentNetwork = 1
    end
    local cfg = networks[currentNetwork]

    log("trying to connect to " .. cfg.ssid)
    wifi.sta.config(cfg)
    wifi.sta.connect()
end

WifiManager.start = function()
    wifi.mode(wifi.STATION)
    wifi.start()

    local wifiCfg = json.read(WIFI_CONFIG_FILE)
    if wifiCfg == nil then
        error("cannot read " .. WIFI_CONFIG_FILE)
    end
    networks = wifiCfg.networks
    local last = json.read(WIFI_LAST)
    if last ~= nil then
        for i, cfg in ipairs(networks) do
            print(cfg.ssid, last.ssid)
            if cfg.ssid == last.ssid then
                table.remove(networks, i)
                break
            end
        end
        table.insert(networks, 1, last)
    end
    WifiManager.OnAPDisconnect:listen(
        function()
            log("AP disconnected")
            connectNext()
        end
    )

    connectNext()
end
tmr.create():alarm(
    100,
    tmr.ALARM_SINGLE,
    function()
        WifiManager.start()
    end
)
return WifiManager
