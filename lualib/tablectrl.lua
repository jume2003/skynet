local skynet = require "skynet"
local socket = require "skynet.socket"
local json = require "json"
local tablectrl = {}
local tm = {}
function tablectrl.init(vtm)
tm = vtm
end

function tablectrl.add(vtid)
 return skynet.call(tm, "lua", "add",vtid)
end
--
function tablectrl.add_user(tid,uid)
  return skynet.call(tm, "lua", "add_user",tid,uid)
end
--
function tablectrl.del(tid)
   return skynet.call(tm, "lua", "del",tid)
end
--
function tablectrl.del_user(tid,uid)
  return skynet.call(tm, "lua", "del_user",tid,uid)
end
--
function tablectrl.get(tid)
  return skynet.call(tm, "lua", "get",tid)
end
--
function tablectrl.get_user(tid,uid)
  return skynet.call(tm, "lua", "get_user",tid,uid)
end



return tablectrl