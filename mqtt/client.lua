MClient = {}
local log = require("core.log"):new("mqtt.client")
local Event = require("core.event")
local defer = require("core.defer")

-- config object:
-- base: MQTT topic base path
-- clientid: MQTT client ID
-- host: MQTT host name to connect to
-- port: MQTT port (optional)
-- lwt: object (optional) MQTT last will
--      topic: topic to where to publish lwt
--      on: message when online. Default "on"
--      off: message when offline. Default "off"

function MClient:new(config)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    config.port = config.port or 1883
    o.base = config.base .. "/"
    o.topics = {}
    o.reconnect = false
    o.OnConnect = Event:new()
    local connect
    local disconnected
    local connected = function()
        log:info("Connection to MQTT established. Base: " .. o.base)
        o.connected = true
        for topicName, topic in pairs(o.topics) do
            o.m:subscribe(topicName, topic.qos, topic.onSubscribe)
        end
        o.OnConnect:fire(o.reconnect)
        if config.lwt ~= nil then
            o:publish(config.lwt.topic, config.lwt.on, 0, true)
        end
        o.reconnect = true
    end
    local connectionFailed
    disconnected = function()
        log:warning("Disconnected from MQTT.")
        o.connected = false
        tmr.create():alarm(5 * 1000, tmr.ALARM_SINGLE, connect)
    end
    local processMessage = function(client, topicName, data)
        local topic = o.topics[topicName]
        if topic ~= nil and topic.onMessage ~= nil then
            local ok, err = pcall(topic.onMessage, data)
            if not ok then
                log:error("Error invoking message handler for %s: %s",
                          topicName, err)
            end
            return
        end
        log:warning("unrecognized topic " .. topicName)
    end
    connect = function()
        log:info("Connecting to MQTT ...")
        if ESP8266 then
            o.m:connect(config.host, config.port, 0, 0, connected, disconnected)
        else
            o.m:connect(config.host, config.port, 0, 0)
        end
    end
    o.m = mqtt.Client(config.clientid, 120)
    o.m:on("connect", connected)
    o.m:on("offline", disconnected)
    o.m:on("message", processMessage)
    if config.lwt ~= nil then
        config.lwt.on = config.lwt.on or "on"
        config.lwt.off = config.lwt.off or "off"
        o:lwt(config.lwt.topic, config.lwt.off, 0, true)
        o.lwtConfig = config.lwt
    end
    connect()
    return o
end

function MClient:parseTopic(topicName)
    if string.byte(topicName, 1) == 58 then -- topics beginning with ":" are considered absolute
        topicName = string.sub(topicName, 2)
    else
        topicName = self.base .. topicName
    end
    return topicName
end

function MClient:subscribe_(topicName, qos, onMessage, onSubscribe)
    local topic = self.topics[topicName]
    qos = qos or 0
    if topic == nil then
        topic = Topic:new(self, topicName, qos, onMessage)
        self.topics[topicName] = topic
    end
    if self.connected then
        self.m:subscribe(topicName, topic.qos, onSubscribe)
    else
        if onSubscribe then
            topic.onSubscribe = function()
                topic.onSubscribe = nil
                onSubscribe()
            end
        end
    end
    return topic
end

function MClient:subscribe(topicName, qos, onMessage, onSubscribe)
    return self:subscribe_(self:parseTopic(topicName), qos, onMessage,
                           onSubscribe)
end

function MClient:getTopic(topicName, qos)
    return Topic:new(self, self:parseTopic(topicName), qos)
end

function MClient:publish(topicName, data, qos, retain, ackCallback)
    qos = qos or 0
    retain = retain and 1 or 0
    self.m:publish(self:parseTopic(topicName), data, qos, retain, ackCallback)
end

function MClient:runOnConnect(callback, once)
    if self.connected then
        defer(callback)
        if once then return end
    end
    self.OnConnect:listen(callback, once)
end

function MClient:subclient(base)
    local o = {}
    setmetatable(o, getmetatable(self))
    o.base = self.base .. base .. "/"
    o.topics = self.topics
    o.m = self.m
    o.OnConnect = self.OnConnect
    return o
end

function MClient:lwt(topicName, message, qos, retain)
    topicName = self:parseTopic(topicName)
    message = message or "offline"
    qos = qos or 0
    retain = retain or false
    self.m:lwt(topicName, message, qos, retain)
end

Topic = {}

function Topic:new(client, topicName, qos, onMessage)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.onMessage = onMessage
    o.client = client
    o.qos = qos
    o.topicName = topicName
    return o
end

function Topic:publish(data, qos, retain, ackCallback)
    qos = qos or self.qos or 0
    if retain then
        retain = 1
    else
        retain = 0
    end
    return self.client.m:publish(self.topicName, data, qos, retain, ackCallback)
end

return MClient
