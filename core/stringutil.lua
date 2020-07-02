local M = {}

function M.pack(...) return {n = select("#", ...), ...} end

function M.cleanargs(args)
    for i = 1, args.n do if args[i] == nil then args[i] = "<nil>" end end
    return args
end

function M.cleanpack(...) return M.cleanargs(M.pack(...)) end

function M.pformat(f, ...)
    local args = M.cleanpack(...)
    return string.format(f, unpack(args))
end

return M
