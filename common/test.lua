Debounced = require("debounced")
CountSwitch = require("countswitch")


di = Debounced:new(5,50)
switch = CountSwitch:new(di, 1000)

switch.callback = function (switch) 
    print("count:" .. switch.count)
end

function onConnect()
    print("Connected to MQTT!")
    topic = client:subscribe("perry",0,function(data) print("received message: " .. data) end, onSubscribe)
end

function onSubscribe()
    print("Subscribed")
    topic:publish("here I am")

end


client=MClient:new("/sonoff/","device1","192.168.0.181", 1883, onConnect)
