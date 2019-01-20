local fmFile="fw-files.json"

local function parseJSON(data)
    local ok, obj = pcall(sjson.decode,data)
    if not ok then
        obj=nil
    end
    return obj
end

local function readJSON(fileName)
    local f = file.open(fileName,"r") 
    if f then
        local data=""
        while true do
            local chunk = f:read()
            if chunk ~= nil then
                print(chunk)
                print (#chunk)
                data = data .. chunk
            else
                break
            end
        end
        f:close()
        return parseJSON(data)
    end
end


local lfm = readJSON(fmFile)
print(lfm.name, lfm.files)
if lfm == nil or not lfm.files then
    print("lfm empty")
    lfm = {files={}}
end

for file, hash in pairs(lfm.files) do
    print(file,hash)
end