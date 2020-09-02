return function(timeout)
    timeout = timeout or 5
    print("\n\n**** Restarting in " .. timeout .. " seconds ...\n")
    tmr.create():alarm(timeout * 1000, tmr.ALARM_SINGLE,
                       function() node.restart() end)
end
