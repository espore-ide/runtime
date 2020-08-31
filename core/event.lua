local Event = {}
local defer = require("core.defer")

function Event:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.listeners = {}
    return o
end

function Event:listen(handler, once) self.listeners[handler] = once or false end

function Event:unlisten(handler) self.listeners[handler] = nil end

function Event:clear() self.listeners = {} end

function Event:fire(...)
    local args = {n = select("#", ...), ...}
    for handler, once in pairs(self.listeners) do
        defer(function() handler(unpack(args)) end)
        if once then self.listeners[handler] = nil end
    end
end

function Event:getTrigger()
    local this = self
    return function(...) this:fire(...) end
end

return Event
