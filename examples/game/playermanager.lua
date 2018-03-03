local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mysocket = require "mysocket"
local CMD = {}
local player_list = {}
local fd_list = {}
local db
--
function CMD.add(info)
  info.uid = tostring(info.uid)
  player_list[tostring(info.uid)] = info
  fd_list[tostring(info.fd)] = info.uid
end
--
function CMD.del(uid)
   local user = CMD.get(uid)
   if user then 
      --保存到数据库
      player_list[tostring(uid)] = nil
      fd_list[tostring(user.fd)] = nil
      fd_list[tostring(-uid)] = nil
   end
end
--
function CMD.set(uid,info)
   local old_fd = player_list[tostring(uid)].fd
   player_list[tostring(uid)] = info
   fd_list[tostring(old_fd)] = nil
   fd_list[tostring(info.fd)] = uid
end
--
function CMD.get(uid)
  if player_list[tostring(uid)] then
      return player_list[tostring(uid)]
  end
  return nil
end
--
function CMD.getbyfd(fd)
  if fd_list[tostring(fd)] then
    local user = CMD.get(fd_list[tostring(fd)])
    return user
  end
  return nil
end
--得到player_list
function CMD.getlist()
  return player_list
end

skynet.start(function()
	db = datacenter.get("db")
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = CMD[cmd]
		if f then
		   skynet.ret(skynet.pack(f(subcmd, ...)))
	    end
	end)
end)
