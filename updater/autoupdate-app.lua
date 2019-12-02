local log = require("core.log"):new("autoupdate")
local updater = require("updater.updater")
local mqtt = require("mqtt.service")

local App = {}

function App:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

--config:
-- period: time in sec to check for updates

function App:init(config)
    self.timer = tmr:create()
    log:info("Will check for updates every %d seconds until MQTT connects", config.period)
    self.timer:alarm(
        config.period * 1000,
        tmr.ALARM_AUTO,
        function()
            self:checkUpdates()
        end
    )
    mqtt:subscribe(
        "espore/global/update/set",
        0,
        function(data)
            self:checkUpdates()
        end
    )
    mqtt:runOnConnect(
        function()
            self.timer:unregister()
            self.timer = nil
            log:info("Will check on updates on MQTT message from now on.")
        end
    )

    self.lastChecked = node.uptime()
end

function App:checkUpdates()
    log:info("Checking for updates ...")
    self.lastChecked = node.uptime()
    updater.update(
        function(result)
            if type(result) == "string" then
                log:error("Error while checking for updates: %s", result)
            else
                log:info("Update check finished successfully")
            end
        end
    )
end

function App:terminate()
    self.timer:stop()
    self.timer:unregister()
    self.timer = nil
end

function App:ui()
    local this = self
    if self._ui == nil then
        self._ui = {
            actions = {
                {
                    type = "button",
                    label = "Check now",
                    action = function()
                        this:checkUpdates()
                    end
                }
            },
            dashboard = {
                {
                    type = "value",
                    label = "Last checked (s ago)",
                    value = function()
                        return tostring(math.floor((node.uptime() - this.lastChecked) / 1000000))
                    end
                }
            }
        }
    end
    return self._ui
end

return App
