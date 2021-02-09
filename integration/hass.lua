local pformat = require("core.stringutil").pformat
local mqtt = require("mqtt.service")
local H = {}

local DISCOVERY_PREFIX = "homeassistant"

H.hclean = function(st) return st:gsub("[^%w-_]", "") end
H.device = function()
    -- "connections" key drives mqtt autodiscovery crazy
    -- local wifi = require("wifi.manager")
    return {
        --[[         connections = {
            {"mac", wifi.info.mac}, {"ip", wifi.info.ip},
            {"ssid", wifi.info.ssid}
        }, ]]
        identifiers = {node.chipid()},
        manufacturer = "espore",
        model = "ESP32",
        name = H.hclean(firmware.name),
        sw_version = firmware.version
    }
end

H.BINARY_SENSOR = "binary_sensor"
H.SENSOR = "sensor"
H.LIGHT = "light"
H.COVER = "cover"
H.DEVICE_AUTOMATION = "device_automation"

-- component
-- nodeId
-- objectId
-- <discovery_prefix>/<component>/[<node_id>/]<object_id>/config

H.publishConfig = function(p)
    p.nodeId = p.nodeId or firmware.name
    p.config.device = H.device()
    if p.component ~= H.DEVICE_AUTOMATION then
        p.config.unique_id = (p.config.unique_id or p.nodeId .. "_" ..
                                 p.objectId)
    end
    mqtt:publish(pformat(":%s/%s/%s/%s/config", DISCOVERY_PREFIX, p.component,
                         H.hclean(p.nodeId), H.hclean(p.objectId)),
                 sjson.encode(p.config), 0, true)

end

return H
