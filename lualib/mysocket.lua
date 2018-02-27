local skynet = require "skynet"
local socket = require "skynet.socket"
local json = require "json"
local mysocket = {}

function mysocket.write(fd,msg)
	
	local ret = json.encode(msg)
	if fd >0 then 
    socket.write(fd, ret.."\r\n")
    if msg.cmd and msg.cmd ~="heartbet" and msg.cmd ~="djshi" then
   	 print("fd"..fd.."->send:"..ret)
	end
	end
	
end

function mysocket.writebro(fds,msg)
    for i=1,#fds,1 do
	    mysocket.write(fds[i],msg)
	end
end

function mysocket.writebel(fds,fd,msg)
    for i=1,#fds,1 do
    	if fds[i] ~= fd then
	   	 mysocket.write(fds[i],msg)
		end
	end
end

return mysocket