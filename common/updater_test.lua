local updater = require("updater")
local pformat = require("pformat")

function unrequire(m)
    package.loaded[m] = nil
    _G[m] = nil
end

updater.check("192.168.1.29", 8080, "", function (err)
    print(pformat("Update result: %s", err))
    unrequire("updater")
    file.remove("fw-etag.txt")
    file.remove("fw-files.json")
    print("heap:", node.heap())
end)
