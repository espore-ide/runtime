local a={b=1, c=4, f=66}
for k,v in pairs(package.loaded) do
    print(k," *** ", v) 
end

print "###########"

for k,v in pairs(_G) do
    print(k," *** ", v) 
end

t = {}
setmetatable(t, { __mode = 'v' })

    local someval = {}
do
    t['foo'] = someval
end

print("before")
for k, v in pairs(t) do
    print(k, v)
end
collectgarbage()
print("collected")
for k, v in pairs(t) do
    print(k, v)
end