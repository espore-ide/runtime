
local GPIO14 = 5
local debounceDelay = 500
local debounceAlarmId = 5
switchstate="OFF"
fuckoff=false

function buttonPushed()
    if fuckoff then
        return
    end
    
    fuckoff=true
    local client = mclient
    if client == nil then
        return
    end
    -- don't react to any interupts from now on and wait 50ms until the interrupt for the up event is enabled
    -- within that 50ms the switch may bounce to its heart's content
    gpio.trig(GPIO14)
    tmr.alarm(debounceAlarmId, debounceDelay, tmr.ALARM_SINGLE, function()
        print("alarm")
        fuckoff=false
        gpio.trig(GPIO14, "low", buttonPushed)
        print("trig set")
    end)
    
    if switchstate=="ON" then
        switchstate="OFF"
    else
        switchstate="ON"
    end
    print("prepublish")
    client:publish("j1switchstate", switchstate, 0, 0, function(client) print("sent switch state") end)
    print("afterpublish")
    
end


gpio.mode(GPIO14, gpio.INT, gpio.PULLUP)
print("setting low")
gpio.trig(GPIO14, "low", buttonPushed)
print("set low")

