local updater = require("updater.updater")

updater.check(
    function(result)
        print("Update result: " .. result)
    end
)
