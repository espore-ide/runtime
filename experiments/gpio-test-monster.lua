local Debounced = require("debounced")
--outputs = {33,26,13,12,27,25,32,5,14,15,2,4}
--inputs = {0,35,39,36,34,16,19,22,23,21,18,17}

outputs = {13, 12, 2, 4, 16, 17, 5, 18, 23, 19, 21, 22}
inputs = {15, 0, 27, 26, 25, 35, 34, 33, 32, 39, 36, 3}

gpio.config({gpio = outputs, dir = gpio.OUT})

for k, v in pairs(outputs) do
    --gpio.write(v, 1)
end

tmr.create():alarm(
    1000,
    tmr.ALARM_SINGLE,
    function()
        for k, v in pairs(outputs) do
            gpio.write(v, 0)
        end
    end
)

function makeCallback(i, pin)
    return function(value)
        print("Input #" .. i .. ",   gpio PIN " .. pin .. " = " .. value)
        gpio.write(outputs[i], 1 - value)
    end
end

for i, pin in pairs(inputs) do
    Debounced:new(
        {
            pin = pin,
            bounce = 50,
            callback = makeCallback(i, pin)
        }
    )
end
