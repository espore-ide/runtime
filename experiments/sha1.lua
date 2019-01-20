local M = {}
local M_mt = { __metatable = {}, __index = M }

M.digest_size = 20
M.block_size = 64

local function rotate_left(x, n)
    return bit.bor(bit.lshift(x,n),bit.rshift(x,(32-n)))
end

function M:new(data)
    if self ~= M then
        return nil, "First argument must be self"
    end
    local o = setmetatable({}, M_mt)

    o._H0 = 0x67452301
    o._H1 = 0xEFCDAB89
    o._H2 = 0x98BADCFE
    o._H3 = 0x10325476
    o._H4 = 0xC3D2E1F0
    o._len = 0
    o._data = ""

    if data ~= nil then
        o:update(data)
    end

    return o
end
setmetatable(M, { __call = M.new })

function M:copy()
    local o = M:new()
    o._H0 = self._H0
    o._H1 = self._H1
    o._H2 = self._H2
    o._H3 = self._H3
    o._H4 = self._H4
    o._data = self._data
    o._len = self._len
    return o
end

function M:update(data)
    local K0 = 0x5A827999
    local K1 = 0x6ED9EBA1
    local K2 = 0x8F1BBCDC
    local K3 = 0xCA62C1D6
    local W
    local temp
    local A
    local B
    local C
    local D
    local E

    if data == nil then
        data = ""
    end

    data = tostring(data)
    self._len = self._len + #data
    self._data = self._data .. data

    while #self._data >= 64 do
        W = {}
        for i=1,64,4 do
            local j = #W+1
            W[j] = bit.lshift(string.byte(self._data, i), 24)
            W[j] = bit.bor(W[j], bit.lshift(string.byte(self._data, i+1), 16))
            W[j] = bit.bor(W[j], bit.lshift(string.byte(self._data, i+2), 8))
            W[j] = bit.bor(W[j], string.byte(self._data, i+3))
        end

        for i=17,80 do
            W[i] = rotate_left(bit.bxor(W[i-3], W[i-8], W[i-14], W[i-16]), 1)
        end

        A = self._H0
        B = self._H1
        C = self._H2
        D = self._H3
        E = self._H4

        for i=1,20 do
            temp = rotate_left(A, 5) + bit.bor(bit.band(B,C),bit.band(bit.bnot(B),D)) + E + W[i] + K0
            E = D
            D = C
            C = rotate_left(B, 30)
            B = A
            A = temp
        end

        for i=21,40 do
            temp = rotate_left(A, 5) + bit.bxor(B,C,D) + E + W[i] + K1
            E = D
            D = C
            C = rotate_left(B, 30)
            B = A
            A = temp
        end

        for i=41,60 do
            temp = rotate_left(A, 5) + bit.bor(bit.band(B,C),bit.band(B,D),bit.band(C,D)) + E + W[i] + K2
            E = D
            D = C
            C = rotate_left(B, 30)
            B = A
            A = temp
        end

        for i=61,80 do
            temp = rotate_left(A, 5) + bit.bxor(B,C,D) + E + W[i] + K3
            E = D
            D = C
            C = rotate_left(B, 30)
            B = A
            A = temp
        end

        self._H0 = self._H0 + A
        self._H1 = self._H1 + B
        self._H2 = self._H2 + C
        self._H3 = self._H3 + D
        self._H4 = self._H4 + E

        self._data = self._data:sub(65, #self._data)
    end
end

function u32ToBytes(u)
   local t = {}
    for i=24,0,-8 do
        t[#t+1] = string.char(bit.band(bit.rshift(u, i) , 0xFF))
    end
    return table.concat(t)
end

function M:finalize()
    local final
    local data
    local len = 0
    local padlen = 0

    final = self:copy()

    padlen = final._len % 64
    if padlen < 56 then
        padlen = 56 - padlen
    else
        padlen = 120 - padlen
    end

    len = final._len * 8
    data = string.char(0x80) ..
        string.rep(string.char(0), padlen-1+4) .. -- +4: assume length < 2³²
        string.char(bit.band(bit.rshift(len, 24), 0xFF)) ..
        string.char(bit.band(bit.rshift(len, 16), 0xFF)) ..
        string.char(bit.band(bit.rshift(len, 8), 0xFF)) ..
        string.char(bit.band(len, 0xFF))

    final:update(data)

    return u32ToBytes(final._H0) ..
        u32ToBytes(final._H1) ..
        u32ToBytes(final._H2) ..
        u32ToBytes(final._H3) ..
        u32ToBytes(final._H4)
end

return M
