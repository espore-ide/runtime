local Debounced = require("debounced")
local ToggleSwitch = require("toggleswitch")

outputs = {33,26,13,12,27,25,32,5,14,15,2,4}
inputs = {0,35,39,36,34,16,19,22,23,21,18,17}

gpio.config( { gpio=outputs, dir=gpio.OUT })

function makeCallback(i, pin)
    return function(value)
        print("PIN " .. pin .. " = " .. value )
        if value == "ON" then
            gpio.write(outputs[i],1)
        else
            gpio.write(outputs[i],0)
        end
    end
end


for i, pin in pairs(inputs) do
    local d = Debounced:new(pin, 100 )
    local t = ToggleSwitch:new(d)
    t.callback = makeCallback(i,pin)
end
