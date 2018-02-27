local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mysocket = require "mysocket"
local CMD = {}
local table_list = {}
local db
--
function CMD.add(vtid)
  table_list[vtid] = {uids = {},tid = vtid}
  print("tablesum:"..#table_list)
end
--
function CMD.add_user(tid,uid)
  table_list[tid].uids[uid] = uid
  print("usersum:"..#table_list[tid].uids)
end
--
function CMD.del(tid)
   table_list[tid] = nil
   print("tablesum:"..#table_list)
end
--
function CMD.del_user(tid,uid)
  table_list[tid].uids[uid] = nil
  print("usersum:"..#table_list[tid].uids)
end
--
function CMD.get(tid)
  if table_list[tid] then
      return table_list[tid]
  end
  return nil
end
--
function CMD.get_user(tid,uid)
  if table_list[tid].uids[uid] then
      return table_list[tid].uids[uid]
  end
  return nil
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
