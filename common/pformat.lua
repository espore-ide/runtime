function pack(...)
    return { n = select("#", ...); ... }
end

function pformat(f, ...)
    local args=pack(...)
    for i=1,args.n do
        if args[i]==nil then
            args[i]="<nil>"
            print(args[i])
        end
    end
    return string.format(f,unpack(args))
end

return pformat
