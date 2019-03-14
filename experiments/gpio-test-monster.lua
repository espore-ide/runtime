local Debounced = require("debounced")
outputs = {33,26,13,12,27,25,32,5,14,15,2,4}
inputs = {0,35,39,36,34,16,19,22,23,21,18,17}

gpio.config( { gpio=outputs, dir=gpio.OUT })

for k, v in pairs(outputs) do
    gpio.write(v, 1)
end


tmr.create():alarm(1000,tmr.ALARM_SINGLE, function()

    for k, v in pairs(outputs) do
        gpio.write(v, 0)
    end

end)


function makeCallback(i, pin)
    return function(value)
        print("PIN " .. pin .. " = " .. value )
        gpio.write(outputs[i],1-value)
    end
end


for i, pin in pairs(inputs) do
    local d = Debounced:new(pin, 50)
    d.callback = makeCallback(i, pin)
end
