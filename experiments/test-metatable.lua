

Test = {}

function Test:__gc()
    print("gc")
end


function Test:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

return Test
