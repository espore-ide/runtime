collectgarbage()
local a=node.heap()
local count=0
local test
local function finish()
    collectgarbage()
    local b=node.heap()
    print(string.format("diff %d-%d=%d", a,b,a-b))
    a=b
    count=count+1

    if count < 10 then
       tmr.create():alarm(50, tmr.ALARM_SINGLE, test)
    else
        print("end")
    end 
end


local function testdownloadfile()
    print ("testdownloadfile", count)
    http.get("http://192.168.43.224:8080/0x2d30aea40329.json", function(code, body, headers)
        print(code)
        tmr.create():alarm(100, tmr.ALARM_SINGLE, finish)
    end)


end


local function test304()

    print ("test304", count)
    local headers = {
        ["If-None-Match"] = '"5c3cc48c-165"'
    }
    http.get("http://192.168.43.224:8080/0x2d30aea40329.json", {headers=headers}, function(code, body, headers)
        print(code)
        tmr.create():alarm(100, tmr.ALARM_SINGLE, finish)
    end)

end


test = test304

test()

