local M = {}

function M.parse(data)
    local ok, obj = pcall(sjson.decode, data)
    if not ok then
        obj = nil
    end
    return obj
end

function M.read(fileName)
    local f = file.open(fileName, "r")
    if not f then
        return nil
    end
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

return M
