local Event = {}

function Event:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.listeners = {}
    return o
end

function Event:listen(handler, once)
    self.listeners[handler] = once or false
end

function Event:unlisten(handler)
    self.listeners[handler] = nil
end

function Event:clear()
    self.listeners = {}
end

function Event:fire(...)
    for handler, once in pairs(self.listeners) do
        handler(...)
        if once then
            self.listeners[handler] = nil
        end
    end
end

function Event:getTrigger()
    local this = self
    return function(...)
        this:fire(...)
    end
end

return Event
