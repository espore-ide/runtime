-- Part of nodemcu-httpserver, handles sending JSON to client.
-- Author: Javier Peletier
return function(t)
    return function(connection, req, args)
        connection:sendHeader(200, "text/json")
        connection:send(sjson.encode(t))
    end
end
