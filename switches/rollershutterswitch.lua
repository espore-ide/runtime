


--switch = ToggleSwitch:new(5, 50, function (switch) print(switch.state) end)

--[[
RollerShutterSwitch= {}
function RollerShutterSwitch:new(buttonPin,relayUpPin, relayDownPin, pulse, bounce, callback)
    o = {state="IDLE"}
    setmetatable(o, self)
    self.__index = self
    gpio.mode(relayUpPin, gpio.OUTPUT)
    gpio.mode(relayDownPin, gpio.OUTPUT)
    createDebouncer(buttonPin, bounce, function(pinState)
        if pinState == gpio.HIGH then
            
        end
    end)

end

]]--