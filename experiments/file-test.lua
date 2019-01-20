
local f = file.open("fw-etag.txt", "r")
local a = f:readline()
print(a)
f:close()

collectgarbage()
print(node.heap())