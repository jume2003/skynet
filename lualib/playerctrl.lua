local skynet = require "skynet"
local socket = require "skynet.socket"
local json = require "json"
local playerctrl = {}
local pm = {}
function playerctrl.init(vpm)
pm = vpm
end

function playerctrl.add(info,fd)
info.fd = fd
return skynet.call(pm, "lua", "add",info)
end

function playerctrl.del(uid)
   return skynet.call(pm, "lua", "del",uid)
end

function playerctrl.set(info)
   return skynet.call(pm, "lua", "set",info.uid,info)
end

function playerctrl.get(uid)
return skynet.call(pm, "lua", "get",uid)
end

function playerctrl.getbyfd(fd)
return skynet.call(pm, "lua", "getbyfd",fd)
end

--得到player_list
function playerctrl.getlist()
  return skynet.call(pm, "lua", "getlist")
end

return playerctrl