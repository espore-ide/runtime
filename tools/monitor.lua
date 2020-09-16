local mqtt = require("mqtt.service")
local mqttsys = mqtt:subclient("espore/" .. firmware.name .. "/sys")
local pkg = require("core.pkg")
local pformat = require("core.stringutil").pformat
local log = require("core.log"):new("monitor")
local infoMonitor = require("tools.info")
local UPDATE_FAIL_FILE = "update.img.fail" -- see init.lua
local trialVersion = true

infoMonitor.subscribe("node", function()
    trialVersion = trialVersion and file.exists(UPDATE_FAIL_FILE)
    local version = trialVersion and firmware.version .. "-trial" or
                        firmware.version
    return {
        chipid = node.chipid(),
        firmwareName = firmware.name,
        firmwareVersion = version
    }
end)

function reportStats(forceReport)
    if trialVersion or forceReport then infoMonitor.update() end
    mqttsys:publish("uptime", pformat("%d", math.floor(node.uptime() / 1000000)))
    mqttsys:publish("free", pformat("%d", node.heap()))
end

function defineSensors()
    local hass = require("integration.hass")
    hass.publishConfig({
        component = hass.SENSOR,
        objectId = "uptime",
        config = {
            json_attributes_topic = mqttsys.base .. "info",
            state_topic = mqttsys.base .. "uptime",
            name = "device " .. firmware.name .. " uptime",
            unit_of_measurement = "s",
            icon = "mdi:timer-sand",
            expire_after = 65
        }
    })
    hass.publishConfig({
        component = hass.SENSOR,
        objectId = "free",
        config = {
            json_attributes_topic = mqttsys.base .. "info",
            state_topic = mqttsys.base .. "free",
            name = "device " .. firmware.name .. " free mem",
            unit_of_measurement = "bytes",
            icon = "mdi:memory"
        }
    })
end

return function(config)
    local restart = function()
        log:warning("Received restart request over MQTT.")
        require("core.restart")()
    end
    local restartTopic = pformat("espore/%s/restart/set", firmware.name)
    mqtt:subscribe("espore/all/restart/set", 0, restart)
    mqtt:subscribe(restartTopic, 0, restart)

    tmr.create():alarm((config.period or 60) * 1000, tmr.ALARM_AUTO,
                       function() reportStats(false) end)

    mqtt:runOnConnect(function()
        defineSensors()
        reportStats(true)
    end)

    log:info("Name: %s, chip id: %s, version: %s. MQTT restart topic: %s%s",
             firmware.name, node.chipid(), firmware.version, mqtt.base,
             restartTopic)

end
