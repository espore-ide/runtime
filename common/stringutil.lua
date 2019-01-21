local M = {}

function M.pack(...)
    return {n = select("#", ...), ...}
end

function M.pformat(f, ...)
    local args = M.pack(...)
    for i = 1, args.n do
        if args[i] == nil then
            args[i] = "<nil>"
        end
    end
    return string.format(f, unpack(args))
end

return M
