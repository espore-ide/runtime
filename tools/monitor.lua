local mqtt = require("mqtt.service")
local mqttsys = mqtt:subclient("espore/" .. firmware.name .. "/sys")
local wifi = require("wifi.manager")
local pkg = require("core.pkg")
local pformat = require("core.stringutil").pformat
local log = require("core.log"):new("monitor")
local hass = require("integration.hass")

local UPDATE_FAIL_FILE = "update.img.fail" -- see init.lua
local trialVersion = true

function reportVersion()
    if trialVersion then trialVersion = file.exists(UPDATE_FAIL_FILE) end
    local version = firmware.version
    if trialVersion then version = version .. "-trial" end
    mqttsys:publish("version", version, 0, true)
end

function reportStats()
    if trialVersion then reportVersion() end
    mqttsys:publish("uptime", pformat("%d", math.floor(node.uptime() / 1000000)))
    mqttsys:publish("free", pformat("%d", node.heap()))
end

function defineInfoSensor()
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

    local info = {
        chipid = node.chipid(),
        ip = wifi.info.ip,
        mac = wifi.info.mac,
        ssid = wifi.info.ssid,
        gw = wifi.info.gw,
        netmask = wifi.info.netmask
    }
    mqttsys:publish("info", sjson.encode(info), 0, true)

end

function defineUptimeSensor()
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
end

function defineFreeMemSensor()
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

function defineVersionSensor()
    hass.publishConfig({
        component = hass.SENSOR,
        objectId = "version",
        config = {
            state_topic = mqttsys.base .. "version",
            name = "device " .. firmware.name .. " version",
            icon = "mdi:tag"
        }
    })
end

return function(config)
    local restart = function()
        log:warning("Received restart request over MQTT.")
        require("core.restart")()
    end
    local restartTopic = pformat("espore/%s/restart/set", firmware.name)
    local gmqtt = require("mqtt.service")
    gmqtt:subscribe("espore/all/restart/set", 0, restart)
    gmqtt:subscribe(restartTopic, 0, restart)

    tmr.create():alarm((config.period or 60) * 1000, tmr.ALARM_AUTO, reportStats)

    mqtt:runOnConnect(function(reconnect)
        reportStats()
        mqttsys:publish("chipid", node.chipid(), 0, true)
        mqttsys:publish("wifi/ip", wifi.info.ip, 0, true)
        mqttsys:publish("wifi/mac", wifi.info.mac, 0, true)
        mqttsys:publish("wifi/ssid", wifi.info.ssid, 0, true)
        mqttsys:publish("wifi/gw", wifi.info.gw, 0, true)
        mqttsys:publish("wifi/netmask", wifi.info.netmask, 0, true)

        defineInfoSensor()
        defineUptimeSensor()
        defineFreeMemSensor()
        defineVersionSensor()
    end)

    log:info("Name: %s, chip id: %s, version: %s. MQTT restart topic: %s%s",
             firmware.name, node.chipid(), firmware.version, gmqtt.base,
             restartTopic)

end
