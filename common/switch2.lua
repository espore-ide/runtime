-- Example Code using OOP Timer
-- Create Object Timers to handle deboucing hardware interrupts
-- Use the Object-oriented programming (OOP) API with tmr.create().
-- Old lua timers with numbers are going to be depreciated!!!!!!!!

local gpioGarageDoorState = 5   -- Pin 2 on nodemcu and GPIO04
local bounce = 50               -- Debounce period. 50ms time used to debounce switches

-- Interrupt vector routine for garagedoor
function GarageDoor()
    -- Debounce sense switch and set door state. 
    -- The state is based on reading the gpio at it's settled hardware state
    GaragedoorTimer:start()
end

-- Create a timer to debounce Garage door strated in by interrupt routine
-- ALARM_SEMI will only fire once.  No need to execute GaragedoorTimer:stop().  
-- Timer will fire again when another interrupt starts it.

switchstate="OFF"

GaragedoorTimer = tmr.create()
GaragedoorTimer:register(bounce, tmr.ALARM_SEMI, function()
        local client = mclient
        if client == nil then
            return
        end
        -- Now check the switch state again as it should have settled down
        if gpio.read(gpioGarageDoorState) == gpio.LOW then
            -- Publish State of Garage Door Closed
                if switchstate=="ON" then
                    switchstate="OFF"
                else
                    switchstate="ON"
                end
                    client:publish("j1switchstate", switchstate, 0, 0, function(client) print("sent switch state2") end)
        end
end)

-- Set up Door Switch pin for Interrupt, (Hardware switches between open circuit and Gnd)
gpio.mode(gpioGarageDoorState, gpio.INT, gpio.PULLUP)

-- Set hardware interrupt handler for garage door.  
-- (Triggered when hardware switch state changes)
gpio.trig(gpioGarageDoorState, "both", GarageDoor)

--  additional code here