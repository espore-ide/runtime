local pformat = require("core.stringutil").pformat
local mqtt = require("mqtt.service")
local H = {}

H.device = function()
    local wifi = require("wifi.manager")
    return {
        connections = {
            {"mac", wifi.info.mac}, {"ip", wifi.info.ip},
            {"ssid", wifi.info.ssid}
        },
        identifiers = node.chipid(),
        manufacturer = "espore",
        model = "ESP32",
        name = firmware.name,
        sw_version = firmware.version
    }
end

H.hclean = function(st) return st:gsub("[^%w-_]", "") end

H.BINARY_SENSOR = "binary_sensor"
H.SENSOR = "sensor"
H.LIGHT = "light"
H.COVER = "cover"

-- component
-- nodeId
-- objectId
-- <discovery_prefix>/<component>/[<node_id>/]<object_id>/config

H.publishConfig = function(p)
    p.nodeId = p.nodeId or firmware.name
    p.config.device = H.device()
    p.config.unique_id = p.config.unique_id or p.nodeId .. "_" .. p.objectId
    mqtt:publish(pformat("%s/%s/%s/config", p.component, H.hclean(p.nodeId),
                         H.hclean(p.objectId)), sjson.encode(p.config), 0, true)

end

return H
