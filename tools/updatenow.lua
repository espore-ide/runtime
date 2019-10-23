local pkg = require("core.pkg")
local log = require("core.log"):new("updatenow")

pkg.require("updater.updater", true).update(
    function(err)
        if err ~= nil then
            log:error("Error updating: %s", err)
        else
            log:info("Update successful")
        end
    end
)
