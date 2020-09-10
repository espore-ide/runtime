local mqtt = require("mqtt.service")
local mqttsys = mqtt:subclient("espore/" .. firmware.name .. "/sys")
local pkg = require("core.pkg")
local pformat = require("core.stringutil").pformat
local log = require("core.log"):new("monitor")
local UPDATE_FAIL_FILE = "update.img.fail" -- see init.lua
local trialVersion = true

function reportInfo()
    trialVersion = trialVersion and file.exists(UPDATE_FAIL_FILE)
    local version = trialVersion and firmware.version .. "-trial" or
                        firmware.version
    local wifi = require("wifi.manager")

    local info = {
        chipid = node.chipid(),
        ip = wifi.info.ip,
        mac = wifi.info.mac,
        ssid = wifi.info.ssid,
        gw = wifi.info.gw,
        netmask = wifi.info.netmask,
        firmwareName = firmware.name,
        firmwareVersion = version
    }
    mqttsys:publish("info", sjson.encode(info), 0, true)
end

function reportStats(forceReport)
    if trialVersion or forceReport then reportInfo() end
    mqttsys:publish("uptime", pformat("%d", math.floor(node.uptime() / 1000000)))
    mqttsys:publish("free", pformat("%d", node.heap()))
end

function defineSensors()
    local hass = require("integration.hass")
    hass.publishConfig({
        component = hass.BINARY_SENSOR,
        objectId = "info",
        config = {
            device_class = "connectivity",
            json_attributes_topic = mqttsys.base .. "info",
            payload_on = mqtt.lwtConfig.on,
            payload_off = mqtt.lwtConfig.off,
            state_topic = mqtt.base .. mqtt.lwtConfig.topic,
            name = "device " .. firmware.name
        }
    })
    hass.publishConfig({
        component = hass.SENSOR,
        objectId = "uptime",
        config = {
            state_topic = mqttsys.base .. "uptime",
            name = "device " .. firmware.name .. " uptime",
            unit_of_measurement = "s",
            icon = "mdi:timer-sand"
        }
    })
    hass.publishConfig({
        component = hass.SENSOR,
        objectId = "free",
        config = {
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

    tmr.create():alarm((config.period or 60) * 1000, tmr.ALARM_AUTO, reportStats)

    mqtt:runOnConnect(function()
        defineSensors()
        reportStats(true)
    end)

    log:info("Name: %s, chip id: %s, version: %s. MQTT restart topic: %s%s",
             firmware.name, node.chipid(), firmware.version, gmqtt.base,
             restartTopic)

end
