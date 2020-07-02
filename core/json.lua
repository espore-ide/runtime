local M = {}

function M.parse(data)
    local ok, obj = pcall(sjson.decode, data)
    if not ok then obj = nil end
    return obj
end

function M.read(fileName)
    local f = file.open(fileName, "r")
    if not f then return nil end
    local data = ""
    while true do
        local chunk = f:read()
        if chunk ~= nil then
            data = data .. chunk
        else
            break
        end
    end
    f:close()
    return M.parse(data)
end

function M.write(fileName, obj)
    local f = file.open(fileName, "w")
    if f then
        local data = sjson.encode(obj)
        f:write(data)
        f:close()
    end
end

function M.merge(a, b)
    for k, v in pairs(b) do
        if type(v) == "table" then
            if type(a[k] or false) == "table" then
                M.merge(a[k] or {}, b[k] or {})
            else
                a[k] = v
            end
        else
            a[k] = v
        end
    end
    return a
end

function M.clean(a)
    local b = {}
    for k, v in pairs(a) do
        local t = type(v)
        if t == "table" then
            b[k] = M.clean(v)
        elseif t == "boolean" or t == "number" or t == "string" then
            b[k] = v
        end
    end
    return b
end

return M
