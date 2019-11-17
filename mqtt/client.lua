MClient = {}
local log = require("core.log"):new("mqtt.client")

function MClient:new(basePath, clientId, host, port, onConnect)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.m = mqtt.Client(clientId, 120)
    o.base = basePath .. "/" .. clientId .. "/"
    o.topics = {}
    o.reconnect = false
    local disconnected
    local connected = function()
        log:info("Connection to MQTT established. Base: " .. o.base)
        o.connected = true
        o.topics = {}
        onConnect(o.reconnect)
        o.reconnect = true
    end
    local connectionFailed
    local connect = function()
        log:info("Connecting to MQTT ...")
        if ESP8266 then
            o.m:connect(host, port, 0, 0, connected, disconnected)
        else
            o.m:connect(host, port, 0, 0, connected)
        end
    end
    disconnected = function()
        log:warning("Disconnected from MQTT.")
        o.connected = false
        tmr.create():alarm(5 * 1000, tmr.ALARM_SINGLE, connect)
    end

    local processMessage = function(client, topicName, data)
        topic = o.topics[topicName]
        if topic ~= nil and topic.onMessage ~= nil then
            topic.onMessage(data)
            return
        end
        log:warning("unrecognized topic " .. topicName)
    end
    o.m:on("connect", connected)
    o.m:on("offline", disconnected)
    o.m:on("message", processMessage)
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
    if topic == nil then
        topic = Topic:new(self, topicName, qos, onMessage)
        self.topics[topicName] = topic
    end
    qos = qos or 0
    self.m:subscribe(topicName, qos, onSubscribe)
    return topic
end

function MClient:subscribe(topicName, qos, onMessage, onSubscribe)
    return self:subscribe_(self:parseTopic(topicName), qos, onMessage, onSubscribe)
end

function MClient:getTopic(topicName, qos)
    return Topic:new(self, self:parseTopic(topicName), qos)
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
    retain = retain or 0
    return self.client.m:publish(self.topicName, data, qos, retain, ackCallback)
end

return MClient
