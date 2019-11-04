local errorHandler = require("net.http.error")
local processRoute

processRoute = function(routes, req)
    for _, route in ipairs(routes) do
        local matches = {string.match(req.request, route.pattern or ".*")}
        if #matches > 0 then
            if type(route.handler) == "function" then
                local ok, func = pcall(route.handler, req, matches)
                if not ok then
                    return errorHandler(503, "Error running handler: " .. func)
                end
                if type(func) == "function" then
                    return func
                else
                    --if a function is not returned, skip to the next handler
                end
            else
                if type(route.handler) == "table" then
                    return processRoute(route.handler, req)
                else
                    return errorHandler(503, "Invalid route handler")
                end
            end
        end
    end
    return errorHandler(404, "No handler matches request")
end

return processRoute
