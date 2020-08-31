local json = require("core.json")
local MClient = require("mqtt.client")
local log = require("core.log"):new("mqtt.service")

local config = json.read("mqtt-config.json")

function subst(st)
    st = st or ""
    return st:gsub("{{name}}", firmware.name)
end

config.clientid = subst(config.clientid)
if config.lwt ~= nil then config.lwt.topic = subst(config.lwt.topic) end

log:info("Connecting to MQTT at %s:%d ...", config.host, config.port)

return MClient:new(config)
