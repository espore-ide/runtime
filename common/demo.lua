MClient = require("mqttmanager")

function onConnect()
    print("Connected to MQTT!")
    topic = client:subscribe("perry",0, onMessage, onSubscribe)
end

function onSubscribe()
    print("Subscribed")
    topic:publish("here I am")

end

function onMessage(data)
    if data == "ON" then
        gpio.write(6, gpio.HIGH)
    else
        gpio.write(6, gpio.LOW)
    end
end

gpio.mode(6, gpio.OUTPUT)

client=MClient:new("/sonoff/","device1","192.168.1.29", 1883, onConnect)
