local Log = {}
local su = require("stringutil")
local pformat = su.pformat
local cleanpack = su.cleanpack

function Log:new(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.name = name
    return o
end

function Log:print(level, f, args)
    print(pformat("[" .. level .. "] (" .. self.name .. ") " .. f, unpack(args)))
end

function Log:error(f, ...)
    local args = cleanpack(...)
    self:print("ERROR", f, args)
end

function Log:warning(f, ...)
    local args = cleanpack(...)
    self:print("WARNING", f, args)
end

function Log:info(f, ...)
    local args = cleanpack(...)
    self:print("INFO", f, args)
end

function Log:debug(f, ...)
    local args = cleanpack(...)
    self:print("DEBUG", f, args)
end

return Log
