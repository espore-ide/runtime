function unrequire(m)
    package.loaded[m] = nil
    _G[m] = nil
end

function TestUpdater()
    local Updater = require("updater")
    Updater.check("http://192.168.1.29:8080", function()
            printf("done!!")
        end)
    unrequire("updater")
end


TestUpdater()