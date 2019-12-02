MClient = {}
local log = require("core.log"):new("mqtt.client")
local Event = require("core.event")

function MClient:new(basePath, clientId, host, port)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.base = basePath .. "/"
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
                log:error("Error invoking message handler for %s: %s", topicName, err)
            end
            return
        end
        log:warning("unrecognized topic " .. topicName)
    end
    connect = function()
        log:info("Connecting to MQTT ...")
        if ESP8266 then
            o.m:connect(host, port, 0, 0, connected, disconnected)
        else
            o.m:connect(host, port, 0, 0)
        end
    end
    o.m = mqtt.Client(clientId, 120)
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
    return self:subscribe_(self:parseTopic(topicName), qos, onMessage, onSubscribe)
end

function MClient:getTopic(topicName, qos)
    return Topic:new(self, self:parseTopic(topicName), qos)
end

function MClient:publish(topicName, data, qos, retain, ackCallback)
    qos = qos or 0
    if retain then
        retain = 1
    else
        retain = 0
    end
    self.m:publish(self:parseTopic(topicName), data, qos, retain, ackCallback)
end

function MClient:runOnConnect(callback, once)
    if self.connected then
        callback()
        if once then
            return
        end
    end
    self.OnConnect:listen(callback, once)
end

function MClient:subclient(basePath)
    local o = {}
    setmetatable(o, getmetatable(self))
    o.base = self.base .. basePath .. "/"
    o.topics = self.topics
    o.m = self.m
    o.OnConnect = self.OnConnect
    return o
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
