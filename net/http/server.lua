-- httpserver
-- Original Author: Marcos Kirsch
-- Modifications for HomeNode by Javier Peletier

local errorHandler = require("net.http.error")

-- Starts web server in the specified port.
return function(conf)
   conf.auth = conf.auth or {}
   conf.auth.realm = conf.auth.realm or "homenode"
   conf.auth.loginCallback = conf.auth.loginCallback or function(user, password)
         return false
      end
   conf.port = conf.port or 80

   local httplog = require("core.log"):new("net.http.server:" .. conf.port)
   local s = net.createServer(net.TCP, 10) -- 10 seconds client timeout

   s:listen(
      conf.port,
      function(connection)
         -- This variable holds the thread (actually a Lua coroutine) used for sending data back to the user.
         -- We do it in a separate thread because we need to send in little chunks and wait for the onSent event
         -- before we can send more, or we risk overflowing the mcu's buffer.
         local connectionThread

         local allowStatic = {
            GET = true,
            HEAD = true,
            POST = false,
            PUT = false,
            DELETE = false,
            TRACE = false,
            OPTIONS = false,
            CONNECT = false,
            PATCH = false
         }

         -- Pretty log function.
         local function log(connection, msg, optionalMsg)
            local port, ip = connection:getpeer()
            if (optionalMsg == nil) then
               httplog:info("%s:%d\t%s", ip, port, msg)
            else
               httplog:info("%s:%d\t%s\t%s", ip, port, msg, optionalMsg)
            end
         end

         local function startServing(fileServeFunction, connection, req, args)
            connectionThread =
               coroutine.create(
               function(fileServeFunction, bufferedConnection, req, args)
                  fileServeFunction(bufferedConnection, req, args)
                  -- The bufferedConnection may still hold some data that hasn't been sent. Flush it before closing.
                  if not bufferedConnection:flush() then
                     log(connection, "closing connection", "no (more) data")
                     connection:close()
                     connectionThread = nil
                     collectgarbage()
                  end
               end
            )

            local BufferedConnectionClass = require("net.http.connection")
            local bufferedConnection = BufferedConnectionClass:new(connection)
            local status, err = coroutine.resume(connectionThread, fileServeFunction, bufferedConnection, req, args)
            if not status then
               log(connection, "Error: " .. err)
               log(connection, "closing connection", "error")
               connection:close()
               connectionThread = nil
               collectgarbage()
            end
         end

         local function processRoute(routes, req)
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

         local function handleRequest(connection, req)
            collectgarbage()
            local method = req.method
            local uri = req.uri
            local fileServeFunction = nil

            fileServeFunction = processRoute(conf.routes, req)

            startServing(fileServeFunction, connection, req, uri.args)
         end

         local function onReceive(connection, payload)
            collectgarbage()
            local auth
            local user = "Anonymous"

            -- as suggest by anyn99 (https://github.com/marcoskirsch/nodemcu-httpserver/issues/36#issuecomment-167442461)
            -- Some browsers send the POST data in multiple chunks.
            -- Collect data packets until the size of HTTP body meets the Content-Length stated in header
            if payload:find("Content%-Length:") or bBodyMissing then
               if fullPayload then
                  fullPayload = fullPayload .. payload
               else
                  fullPayload = payload
               end
               if
                  (tonumber(string.match(fullPayload, "%d+", fullPayload:find("Content%-Length:") + 16)) >
                     #fullPayload:sub(fullPayload:find("\r\n\r\n", 1, true) + 4, #fullPayload))
                then
                  bBodyMissing = true
                  return
               else
                  --print("HTTP packet assembled! size: "..#fullPayload)
                  payload = fullPayload
                  fullPayload, bBodyMissing = nil
               end
            end
            collectgarbage()

            -- parse payload and decide what to serve.
            local req = require("net.http.request")(payload, conf.translatePath)
            log(connection, req.method, req.request)
            if conf.auth.enabled then
               auth = require("net.http.basicauth")
               user = auth.authenticate(payload, conf.auth.loginCallback) -- authenticate returns nil on failed auth
            end

            if user and req.methodIsValid and (req.method == "GET" or req.method == "POST" or req.method == "PUT") then
               req.user = user
               handleRequest(connection, req, handleError)
            else
               local args
               local fileServeFunction
               if not user then
                  fileServeFunction = errorHandler(401, "Not Authorized")
                  args = {
                     headers = {auth.authErrorHeader(conf.auth.realm)}
                  }
               elseif req.methodIsValid then
                  fileServeFunction = errorHandler(501, "Not Implemented")
               else
                  fileServeFunction = errorHandler(400, "Bad Request")
               end
               startServing(fileServeFunction, connection, req, args or {})
            end
         end

         local function onSent(connection, payload)
            collectgarbage()
            if connectionThread then
               local connectionThreadStatus = coroutine.status(connectionThread)
               if connectionThreadStatus == "suspended" then
                  -- Not finished sending file, resume.
                  local status, err = coroutine.resume(connectionThread)
                  if not status then
                     log(connection, "Error: " .. err)
                     log(connection, "closing connection", "error")
                     connection:close()
                     connectionThread = nil
                     collectgarbage()
                  end
               elseif connectionThreadStatus == "dead" then
                  -- We're done sending file.
                  log(connection, "closing connection", "thread is dead")
                  connection:close()
                  connectionThread = nil
                  collectgarbage()
               end
            end
         end

         local function onDisconnect(connection, payload)
            -- this should rather be a log call, but log is not available here
            --            print("disconnected")
            if connectionThread then
               connectionThread = nil
               collectgarbage()
            end
         end

         connection:on("receive", onReceive)
         connection:on("sent", onSent)
         connection:on("disconnection", onDisconnect)
      end
   )
   return s
end
