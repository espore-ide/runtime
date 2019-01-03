Debounced = require("debounced")
CountSwitch = require("countswitch")


inputs = {4,5,39,36,35,34,33}

for _, pin in ipairs(inputs) do
    print("Creating for " .. pin)
    local di = Debounced:new(pin,50)
    local setCallback = function(pin)
            di.callback=function(x)
                print("Change in pin " .. pin)
            end
        end
    setCallback(pin)
end