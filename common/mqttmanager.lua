MClient = {}

function MClient:new(basePath, clientId, host, port, onConnect)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.m=mqtt.Client(clientId, 120)
    o.base = basePath .. clientId .. "/"
    o.topics={}
    local connected = function()
        print("Connection to MQTT established. Base: " .. o.base)
        o.connected=true
        onConnect()
    end
    local connect = function()
        print("Connecting to MQTT ...")
        o.m:connect(host, port, 0, connected, connectionFailed)
    end
    local connectionFailed = function(client, reason)
        o.connected=false
        print("Connection to MQTT failed. Reason: " .. reason)
        tmr.create():alarm(5 * 1000, tmr.ALARM_SINGLE, connect)
    end
    local processMessage = function(client, topicName, data)
        topic = o.topics[topicName]
        if topic ~= nil and topic.onMessage ~= nil then
            topic.onMessage(data)
            return
        end
        print("Warning: unrecognized topic " .. topicName)
    end
    o.m:on("offline", function()
        print("Disconnected from MQTT.")
        o.connected=false
        connect()
    end)

    o.m:on("message", processMessage)
    connect()
    return o
end

function MClient:subscribe(topicName, qos, onMessage, onSubscribe)
    local fullTopicName = self.base .. topicName
    local topic = self.topics[fullTopicName]
    if topic == nil then
        topic = Topic:new(self,topicName, onMessage)
        self.topics[fullTopicName]=topic
    end
    self.m:subscribe(fullTopicName, qos, onSubscribe)
    return topic
end

Topic = {}

function Topic:new(client, topicName, onMessage)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.onMessage = onMessage
    o.client = client
    o.topicName = topicName
    return o
end

function Topic:publish(data, qos, retain, ackCallback)
    if qos == nil then
        qos=0
    end
    if retain == nil then
        retain = 0
    end
    return self.client.m:publish(self.client.base .. self.topicName, data, qos, retain, ackCallback)
end

return MClient
