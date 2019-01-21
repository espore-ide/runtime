local D = {}

function D.add(...)
    for _, fileName in ipairs(arg) do
        D[#D + 1] = fileName
    end
end

return D
