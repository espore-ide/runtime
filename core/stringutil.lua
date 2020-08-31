local M = {}

function M.pack(...) return {n = select("#", ...), ...} end

function M.pformat(f, ...)
    for i = 1, arg.n do if arg[i] == nil then arg[i] = "<nil>" end end

    return string.format(f, unpack(arg))
end

return M
