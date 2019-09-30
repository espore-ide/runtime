local ToggleSwitch = require("toggleswitch")

ts1 = ToggleSwitch:new({
    pin=0,
    bounce=50,
    callback=function(state) print(state) end})