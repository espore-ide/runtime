local json = require("json")
local MClient = require("mqttclient")
local log = require("log"):new("mqtt-service")
local Event = require("event")

local config = json.read("mqtt-config.json")
if config.clientid == "$" then
    config.clientid = firmware.name
end

log:info("Connecting to MQTT at %s:%d ...", config.host, config.port)

local mqttclient
mqttclient =
    MClient:new(
    config.base,
    config.clientid,
    config.host,
    config.port,
    function(reconnect)
        config = nil
        log:info("MQTT service connected")
        mqttclient.OnConnect:fire(reconnect)
    end
)

mqttclient.OnConnect = Event:new()

return mqttclient
