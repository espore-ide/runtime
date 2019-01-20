local Event = {}

function Event:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.listeners = {}
    return o
end

function Event:listen(handler)
    self.listeners[handler] = handler
end

function Event:unlisten(handler)
    self.listeners[handler] = nil
end

function Event:clear()
    self.listeners = {}
end

function Event:fire(...)
    for _, listener in pairs(self.listeners) do
        listener(...)
    end
end

function Event:getTrigger()
    return function(...)
        self:fire(...)
    end
end

return Event
