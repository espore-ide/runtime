m=require("mqttclient"):new("base", "clientid", "192.168.1.34", 1883, function (reconnect) 
    print ("mqtt connected" , reconnect)

    t1=m:subscribe("perry", 0, function(data)
        print("perry", data)
    end)

    t2=m:subscribe(":mason", 0, function(data)
        print("mason", data)
    end)

    t3 = m:getTopic(":jander/clander")
    t4 = m:getTopic("color")
    
end)