
gpio.mode(4, gpio.OUTPUT)

timer = tmr.create():alarm(200, tmr.ALARM_AUTO, function()
    
    if led4 == gpio.HIGH then
        led4=gpio.LOW
    else
        led4=gpio.HIGH
    end
    gpio.write(4, led4)

end)
