


gpio.config( { gpio={3}, dir=gpio.IN, pull=gpio.PULL_UP })
gpio.config( { gpio={5}, dir=gpio.OUT })


gpio.trig(3, gpio.INTR_UP_DOWN, function (pin,level)
    gpio.write(5,level)
end)