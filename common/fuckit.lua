for i=1,50 do

    mclient:publish("j1switchstate", "ON", 0, 0, function(client) print("sent switch state") end)

end