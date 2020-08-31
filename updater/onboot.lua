local M = {}
local Event = require("core.event")
local pkg = require("core.pkg")
local defer = require("core.defer")
local WifiManager = require("wifi.manager")
local updater = require("updater.updater")

M.OnUpdate = Event:new()

local log = require("core.log"):new("update.onboot")

local function updateonboot(info, reconnect)
    if reconnect then return end
    log:info("Checking for updates on boot...")
    updater.update(function(err) M.OnUpdate:fire(err) end)
end

WifiManager.OnConnect:listen(updateonboot, true)
defer(function() pkg.unload("updater.onboot") end)

return M
