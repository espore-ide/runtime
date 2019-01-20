local function pack(...)
    return {n = select("#", ...), ...}
end

local M = {}

function M.pformat(f, ...)
    local args = pack(...)
    for i = 1, args.n do
        if args[i] == nil then
            args[i] = "<nil>"
        end
    end
    return string.format(f, unpack(args))
end

return M
