local Telnet = {}
local WifiManager = require("wifi.manager")
local log = require("core.log"):new("telnet")

-- Telnet server
local telnet_srv = net.createServer(net.TCP, 180)

local function startTelnet(port, motd)
    log:info("Started Telnet server on port " .. port)
    telnet_srv:listen(
        port,
        function(socket)
            -- put your device in service mode here (optional)
            -- ...
            local closed = false
            local fifo = {}
            local fifo_drained = true

            local function sender(c)
                if closed then
                    return
                end
                if #fifo > 0 then
                    c:send(table.remove(fifo, 1))
                else
                    fifo_drained = true
                end
            end

            local function s_output(str)
                if str ~= "" then
                    table.insert(fifo, str)
                    if socket ~= nil and fifo_drained then
                        fifo_drained = false
                        sender(socket)
                    end
                end
            end

            node.output(s_output, 0) -- re-direct output to function s_ouput.

            socket:on(
                "receive",
                function(c, l)
                    node.input(l) -- works like pcall(loadstring(l)) but support multiple separate line
                end
            )
            socket:on(
                "disconnection",
                function(c)
                    node.output(nil) -- un-regist the redirect output function, output goes to serial
                    -- restore normal operation here (optional)
                    -- ...
                end
            )
            socket:on("sent", sender)

            exit = function()
                closed = true
                socket:close()
                telnet_srv:close()
                node.output(nil) -- un-regist the redirect output function, output goes to serial
                startTelnet(port, motd)
            end
            if motd ~= nil then
                print(motd)
            end
        end
    )
end

ls = function()
    l = file.list()
    for k, v in pairs(l) do
        print(k .. ", " .. v)
    end
end

WifiManager.OnConnect:listen(
    function()
        startTelnet(23, "Welcome to " .. firmware.name)
    end
)

return Telnet
