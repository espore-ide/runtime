local log = require("core.log"):new("autoupdate")
local updater = require("updater.updater")
local mqtt = require("mqtt.service")
local pformat = require("core.stringutil").pformat

local App = {}

function App:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- config:
-- period: time in sec to check for updates
function App:init(config)
    self.timer = tmr.create()

    local function checkUpdatesFromMQTT()
        self:checkUpdates("mqtt message received")
    end

    log:info("Will check for updates every %d seconds until MQTT connects",
             config.period)
    self.timer:alarm(config.period * 1000, tmr.ALARM_AUTO,
                     function() self:checkUpdates("timer tick") end)
    mqtt:subscribe("espore/all/update/set", 0, checkUpdatesFromMQTT)
    mqtt:subscribe(pformat("espore/%s/update/set", firmware.name), 0,
                   checkUpdatesFromMQTT)
    mqtt:runOnConnect(function()
        self.timer:unregister()
        self.timer = nil
        log:info("Will check on updates on MQTT message from now on.")
    end)

    self.lastChecked = node.uptime()
    updateNow = function() self:checkUpdates("User command") end
end

function App:checkUpdates(reason)
    log:info("Checking for updates due to %s", reason)
    self.lastChecked = node.uptime()
    updater.update(function(result)
        if type(result) == "string" then
            log:error("Error while checking for updates: %s", result)
        else
            log:info("Update check finished successfully")
        end
    end)
end

function App:terminate()
    self.timer:stop()
    self.timer:unregister()
    self.timer = nil
end

return App
