local log = require("core.log"):new("dimmer")
local pkg = require("core.pkg")

return function(config)
    pkg.unload("dimmer.dimmer")
    dimmer.setup({syncGpio = config.syncGpio})
    tmr.create():alarm(3000, tmr.ALARM_SINGLE, function()
        local mains = dimmer.mainsFrequency() / 100
        if mains == 0 then
            log:error("Did not detect mains")
        else
            log:info("Perceived mains frequency is %g Hz", mains)
        end
    end)
end
