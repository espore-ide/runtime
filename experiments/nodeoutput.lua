

count = 0
last =""
count2 =0

function counter(st)
    count = count + #st
    last = st
end

function otherfunc(st)
    count2 = count2 + #st
end


node.output(counter)