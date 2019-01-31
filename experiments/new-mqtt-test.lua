local Event = require("event")

print(node.heap())

tick = Event:new()

local t = tmr.create()
local count = 0
t:alarm(1000, tmr.ALARM_AUTO, function()
    tick:fire()
end)



local n = 0
function createClient()
    local id=n
    n=n+1

    print ("creating #" .. id)
    local a = mqtt.Client("clientId#" .. id, 10)
    
    a:lwt("goodbye", "bye!!!" .. id)
    
    a:on("message", function (x,y, z)
        print("message clientid #" .. id, x, y, z)
    end)

    a:on("connect", function ()
        print ("client " .. id .. " connected")
    end)

    a:on("offline", function ()
        print ("client " .. id .. " is now offline")
    end)

    a:connect("192.168.0.234", 1883, 0, function(client)
      print(client, "connected #" .. id )
    
        a:subscribe("thetopic", 0, function(client)
            print(client, "subscribed")
            
        end)

        local count = 0
        local timer
        timer = function()
                print ("timer for #" .. id)
                count = count +1
                if count > 20 then
                    tick:unlisten(timer)
                    a=nil
                    return
                end
                a:publish("topic" .. id, "" .. node.uptime(), 0, 0)
        
            end
         tick:listen(timer)    
    
    end,
    function(client, reason)
      reason = reason or 0
      print(client, "client " .. id .." connection attempt failed. reason: " .. reason)
      a=nil
    end)
end


m = mqtt.Client("esp32", 120)
m:connect("192.168.1.34", 1883, 0, function(client)
  print("connected, schedule topic subscriptions")
  client:subscribe("topic1", 0,
    function (client)
      client:subscribe("topic2", 0, function () print("subscriptions done") end)
    end)
end,
function(client, reason)
  print("failed reason: " .. reason)
end)

