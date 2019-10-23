otainfo = function()
    boot_part, next_part, info = otaupgrade.info()
    print("Booted: " .. boot_part)
    print("  Next: " .. next_part)
    for p, t in pairs(info) do
        print("@ " .. p .. ":")
        for k, v in pairs(t) do
            print("    " .. k .. ": " .. v)
        end
    end
    print("Running version: " .. info[boot_part].version)
end

function otaupdate()
    local f = file.open("NodeMCU.bin", "r")
    otaupgrade.commence()

    repeat
        data = f:read()
        if data ~= nil then
            otaupgrade.write(data)
        end
    until data == nil
    f:close()
    print("finished writing")
    otaupgrade.complete(1)
end
