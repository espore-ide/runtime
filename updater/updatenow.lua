local updater = require("updater")
local siteconfig = require("site-config")

print("Checking for updates...")

updater.check(
    siteconfig.UPDATE_HOST,
    siteconfig.UPDATE_PORT,
    "",
    function(result)
        if type(result) == "string" then
            print("Error updating device:", result)
            return
        end
        if result > 0 then
            print(string.format("%d files updated. Restarting...", result))
            tmr.create():alarm(
                1000,
                tmr.ALARM_SINGLE,
                function()
                    node.restart()
                end
            )
            return
        else
            print("No updates found.")
        end
    end
)
