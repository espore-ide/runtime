-- defer yields to the OS for 1ms and then runs func
return function(func) tmr.create():alarm(1, tmr.ALARM_SINGLE, func) end
