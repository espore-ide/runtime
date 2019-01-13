local string = require("string")

local M = {}
local M_mt = { __metatable = {}, __index = M }

M.digest_size = 8
M.block_size = 8

local function digest_int(cs)
end

function M:new(data)
    if self ~= M then
        return nil, "First argument must be self"
    end
    local o = setmetatable({}, M_mt)
    o._crc = 0xFFFFFFFF
    
    if data ~= nil then
        o:update(data)
    end

    return o
end
setmetatable(M, { __call = M.new })

function M:copy()
    local o = M:new()
    o._crc = self._crc
    return o
end

function M:update(data)
    local byte
    local mask

    if data == nil then
        data = ""
    end

    data = tostring(data)

    for i=1,#data do
        byte = string.byte(data, i)
        self._crc  = bit.bxor(self._crc , byte)
        for j=1,8 do
            mask       = bit.band(self._crc , 1) * -1
            self._crc  = bit.bxor(bit.rshift(self._crc , 1) , bit.band(0xEDB88320 , mask))
        end
    end
end

function M:digest()
    return bit.bnot(self._crc)
end

function M:hexdigest()
    return string.format("%08x", self:digest())
end

hasher=M:new()
hasher:update("hello")
print(hasher:hexdigest())


return M