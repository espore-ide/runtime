local Log = {}

function Log:new(name)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.name = name
    return o
end

function Log:print(level, f, args)
    for i = 1, args.n do if args[i] == nil then args[i] = "<nil>" end end
    print(string.format("[ " .. level .. " ] (" .. self.name .. ") " .. f,
                        unpack(args)))
end

function Log:error(f, ...) self:print("ERROR", f, arg) end
function Log:warning(f, ...) self:print("WARNING", f, arg) end
function Log:info(f, ...) self:print("INFO", f, arg) end
function Log:debug(f, ...) self:print("DEBUG", f, arg) end

return Log
