local json = require("core.json")
local pformat = require("core.stringutil").pformat

local i = 0
local portmap = {}
repeat
    local p = json.read(pformat("portmap%d.json", i))
    if p == nil then
        break
    end
    portmap = json.merge(portmap, p)
    i = i + 1
until false

portmap.outputPin = function(outputNum)
    return portmap.outputs[outputNum].pin
end

portmap.inputPin = function(inputNum)
    return portmap.inputs[inputNum].pin
end

if not portmap.outputs or not portmap.inputs then
    error("Portmap: no inputs/outputs defined. portmap0.json missing?")
end

return portmap
