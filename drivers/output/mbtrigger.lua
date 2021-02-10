local mqtt = require("mqtt.service")
local defer = require("core.defer")

local count2type = {
    "button_long_press", "button_short_press", "button_double_press",
    "button_triple_press", "button_quadruple_press", "button_quintuple_press"
}

return function(name, description, topic)
    local triggerTopic = mqtt:getTopic(topic, 0)
    mqtt:runOnConnect(function(reconnect)
        local hass = require("integration.hass")
        for _, type in ipairs(count2type) do
            defer(function()
                hass.publishConfig({
                    component = hass.DEVICE_AUTOMATION,
                    objectId = hass.hclean(name .. "_" .. type),
                    config = {
                        automation_type = "trigger",
                        topic = mqtt.base .. topic,
                        payload = type,
                        type = type,
                        subtype = description
                    }
                })
            end)
        end
    end)
    return function(count)
        local type = count2type[count + 1]
        if type ~= nil then triggerTopic:publish(type) end

    end
end

