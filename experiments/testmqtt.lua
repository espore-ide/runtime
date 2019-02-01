
COMMAND_TOPIC="javi1command"
STATE_TOPIC="javi1state"

function testmqtt ()

-- init mqtt client without logins, keepalive timer 120s
m = mqtt.Client("clientid", 120)

-- setup Last Will and Testament (optional)
-- Broker will publish a message with qos = 0, retain = 0, data = "offline" 
-- to topic "/lwt" if client don't send keepalive packet
m:lwt("/lwt", "offline", 0, 0)

m:on("connect", function(client) print ("connected") end)
m:on("offline", function(client) 
    print ("offline")
    mclient=nil
    end)

-- on publish message receive event
m:on("message", processMessage)

-- on publish overflow receive event
m:on("overflow", function(client, topic, data)
  print(topic .. " partial overflowed message: " .. data )
end)

-- for TLS: m:connect("192.168.11.118", secure-port, 1)
m:connect("192.168.0.181", 1883, 0, function(client)
  print("connected")
  -- Calling subscribe/publish only makes sense once the connection
  -- was successfully established. You can do that either here in the
  -- 'connect' callback or you need to otherwise make sure the
  -- connection was established (e.g. tracking connection status or in
  -- m:on("connect", function)).

  -- subscribe topic with qos = 0
  client:subscribe(COMMAND_TOPIC, 0, function(client) print("subscribe success") end)
  -- publish a message with data = hello, QoS = 0, retain = 0
  client:publish(COMMAND_TOPIC, "PERRY", 0, 0, function(client) print("sent") end)
  mclient=client
end,
function(client, reason)
  print("failed reason: " .. reason)
end)

m:close();
-- you can call m:connect again


end

function processMessage(client,topic, data)
    print(topic .. ":" .. data)
    if topic == COMMAND_TOPIC then
        local state
        if data == "ON" then
            gpio.write(6, gpio.HIGH)
            state="ON"
        else
            gpio.write(6, gpio.LOW)
            state="OFF"
        end
        client:publish(STATE_TOPIC, state, 0, 0, function(client) print("sent state") end)
    end
end




testmqtt()

