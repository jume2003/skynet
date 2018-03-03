local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mysocket = require "mysocket"
local pm = require "playerctrl"
local tm = require "tablectrl"
local utils = require "myfunlib.base_tips.utils"
local MsgList = require 'MsgList'
local comman_msg = MsgList.comman
local CMD = {}
local db
local group_list = {}
--创建房间
local ret_create = {mode="hall",cmd = "create",info ={game_id=1}}
--加入房间 进入游戏
local ret_join = {mode="hall",cmd = "create",info ={gid = 1,game_id=1}}
--退出房间
local ret_exit = {mode="hall",cmd = "create",info ={gid=1}}
--提出解散房间
local ret_tidel = {mode="any",cmd = "tidel",info ={name=""}}
--是否同意解散房间
local ret_agdel = {mode="any",cmd = "agdel",info ={name="",agree=false}}

function echo_user(user,uid)
	if user[tostring(uid)] then
	   return user[tostring(uid)]
	end
	return nil
end

function get_group(uid)
         for key, value in pairs(group_list) do    	
         	if echo_user(value.uids,uid) then
         		return value
         	end
         end  
         return nil
end

function get_groupfds(group)
    local fd_list = {}
    for k, v in pairs(group.uids) do
	    local user = pm.get(v)
		if user then
		   table.insert(fd_list,user.fd)
		end
	end
	return fd_list
end
--没1分种清理一次pm 当user.fd 为负数时且不在 不在任何group中只就可以把user删了
--随便保存一下数据
function cls_pm()
	local player_list = pm.getlist()
	for k, v in pairs(player_list) do
		if v.fd<0 and get_group(v.uid)==nil then
			pm.del(v.uid)
			print("pm clear "..v.uid)
		end
	end
end

function speed_test(uid)
   --不在任何组中 创建组
    pm.add({uid = uid,nick_name = "123",touxian = "123"},-uid)
    msg = {fd = -uid,rule={wanfa=1,difen=1,jushu=8,fanfei=1,ip=0}}

  	CMD.create_group(msg)
end

function CMD.disconnect(fd)
	--断开只改fd为0（不会影响游戏逻辑中用uid从pm中更新fd_list
	-- 和用fd_list从pm得到user
	--对于原路返回的fd不可能为负数所以user在pm得不到
	local user = pm.getbyfd(fd)
	if user then
	user.fd = -user.uid
	pm.set(user)
	print("disconnect uid"..user.uid)
	end
end
--解散房间
function CMD.tidel(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
	  	local group = get_group(user.uid)
	    if group then 
	    	local uid = user.uid
	    	local gid = group.gid
	    	group_list[gid].agdel = {}
	    	for k, v in pairs(group.uids) do
	    		group_list[gid].agdel[v] = false
	    	end
	    	group_list[gid].agdel[uid] = true
	    	ret_tidel.info.name = user.nick_name
	    	local fd_list = get_groupfds(group)
	    	mysocket.writebel(fd_list,user.fd,ret_tidel)
	    else
	    	comman_msg.showbox.info.msg = "已不在房间中"
    		mysocket.write(user.fd, comman_msg.showbox)
	    end
	end
end
--是否同意解散房间
function CMD.agdel(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
	  	local group = get_group(user.uid)
	    if group then 
	    	local uid = user.uid
	    	local gid = group.gid
	    	local is_del = true
	    	group_list[gid].agdel[uid] = msg.info.agree
	    	for k, v in pairs(group.uids) do
	    		if group_list[gid].agdel[v] == false then
	    			is_del = false
	    		end
	    	end
	    	local fd_list = get_groupfds(group)
	    	if msg.info.agree == false then
	    		comman_msg.showbox.info.msg = user.nick_name.." 拒绝解散"
    			mysocket.writebel(fd_list,user.fd,comman_msg.showbox)
	    	end
	    	--解散房间
	    	if is_del then
	    		print("remove group and stop ser")
	    		comman_msg.showbox.info.msg = "游戏已解散请退出"
    			mysocket.writebro(fd_list,comman_msg.showbox)
		    	skynet.send(group.ser, "lua", "disconnect")
		    	group_list[group.gid] = nil
	    	end
	    end
	end
end
--
function CMD.exit_group(msg)
	    local user = pm.getbyfd(msg.fd)
	    if user then
	    	local group = get_group(user.uid)
	    	if group then 
	    		--只有一个玩家时才可以退出
	    		local user_count = 0
	    		for k, v in pairs(group.uids) do
	    			user_count = user_count+1
	    		end
	    		--100 等待准备
				--102 游戏结束局数已到
	    		local game_state = skynet.call(group.ser, "lua", "game_state",msg)
	    		--当玩家需要退出房间时要从游戏逻辑中判断是否能退出
	    		if game_state == 102 or ((user_count<=1 or group.fzuid ~= user.uid) and game_state == 100 ) then
		    		for k, v in pairs(group.uids) do
		    		   if v == user.uid then
		    		   group.uids[k] = nil
		    		   skynet.call(group.ser, "lua", "exit_group",msg)
		    		   print(user.uid.." exit_group")
		    		   end
		    		end
		    		if skynet.table_size(group.uids)==0 then 
		    	   		print("remove group and stop ser")
		    	   		skynet.send(group.ser, "lua", "disconnect")
		    	   		group_list[group.gid] = nil
		    		end
	    		end
	    	end
	    end
end
--
function CMD.join_group(msg)
	    local user = pm.getbyfd(msg.fd)
	    if user then
	    	local group = get_group(user.uid)
	    	local ret_msg = {mode="hall",cmd="showbox",info={msg = ""}}
	    	if group then 
   				ret_join.info.gid = group.gid
   				ret_join.info.game_id = group.game_id
   				mysocket.write(msg.fd, ret_join)
   				--重启游戏
   				skynet.send(group.ser, "lua", "resgame",msg)
	    		print("已在组中")
	    	else 
	    	   group =group_list[msg.gid]
	    	   if group and skynet.table_size(group.uids)< group.maxuser then
                	group.uids[tostring(user.uid)] = user.uid
                	ret_join.info.gid = group.gid
   					ret_join.info.game_id = group.game_id
   					mysocket.write(msg.fd, ret_join)
   					skynet.send(group.ser, "lua", "join",msg)
                	print("房间 join ok "..user.uid)
               elseif group == nil then
               		ret_msg.info.msg = "房间不存在"
   					mysocket.write(msg.fd, ret_msg)
               		print("房间不存在")
               else
               		ret_msg.info.msg = "房间已满人"
   					mysocket.write(msg.fd, ret_msg)
               		print("房间已满人")
	    	   end
	    	end
	    end
end
--
local g_robid = 100000
function CMD.create_group(msg)
	    local fd = msg.fd
	    local ser = nil
        local index = (#group_list)+1;
        --查找是否在其中的一个组里
        local user = pm.getbyfd(fd)
        if user then 
           local group = get_group(user.uid)
           	if group then
        	  --已在组中 客户要进入游戏中
        	  	ret_join.info.gid = group.gid
   				ret_join.info.game_id = group.game_id
   				mysocket.write(msg.fd, ret_join)
   				--重启游戏
   				skynet.send(group.ser, "lua", "resgame",msg)
        	 	print("已在组中")
            else
				--不在任何组中 创建组
				--扣房费
	        	local fanfei = {1,2}
	        	local needfanfei = fanfei[msg.rule.fanfei]
	        	if user.card - needfanfei >=0  then
	        		user.card = user.card-needfanfei
	        		pm.set(user)
	        		local ser = skynet.newservice("kddmj")
		        	group = {uids = {},fzuid = 0,agdel={},ser = ser,game_id = 1,maxuser = 5,rule={}}
		        	group.uids[tostring(user.uid)] = user.uid
		        	group.fzuid = user.uid
		        	group.rule = msg.rule
		        	group.gid = math.random(100000,888888)+user.uid
		        	group_list[group.gid] = group
		        	skynet.call(ser, "lua", "start",group.gid)
		        	skynet.send(group.ser, "lua", "join",msg)
		        	
			        for i=2,3,1 do
			        local rouid = -(g_robid)
			        g_robid = g_robid+1
			        --添加机器人 
			        pm.add({uid = rouid,nick_name = "123",touxian = "http://thirdwx.qlogo.cn/mmopen/vi_32/3EB7dFdNRKmjHmkRpGvjqZh2ia0Oj69tticicvb3T2lsFDricb4Sc7YPHhPlJvolJ8uv5GaibSk65q1g4IDz5R5hS1w/132"},rouid)
			        --机器人加入
			        CMD.join_group({fd = rouid,uid = rouid,gid=group.gid})
			        skynet.send(group.ser, "lua", "ready",{fd = rouid})
			        end
			        print("创建房间 "..group.gid)
			        ret_create.info.gid = group.gid
	   				ret_create.info.game_id = group.game_id
	   				mysocket.write(msg.fd, ret_create)
	   			else
	   				comman_msg.showbox.info.msg = "房卡不足请充值"
    				mysocket.write(msg.fd,comman_msg.showbox)
	        	end
            end
        else
        	--no login
        end
end
--
function CMD.game_msg(msg)
	     local user = pm.getbyfd(msg.fd)
         if user then 
         	local group = get_group(user.uid)
            if group then
               msg.info.fd = msg.fd
               skynet.call(group.ser, "lua", msg.game_cmd , msg.info)
            end
         end
end

skynet.start(function()
	db = datacenter.get("db")
    pm.init(datacenter.get("pm"))
    tm.init(datacenter.get("tm"))
    skynet.fork(function()
    	skynet.sleep(200)
    	for i=1,200,1 do
    		--speed_test(os.time()+math.random(5000,8000))
    		--print("speed_test "..i)
    	end
    end)
    

    skynet.fork(function()
		while true do
			datacenter.set("group_list",group_list)
			skynet.sleep(10)
		end
	end)
	skynet.fork(function()
		while true do
			cls_pm()
			skynet.sleep(1000*60)
		end
	end)
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = CMD[cmd]
		if f then
		   skynet.ret(skynet.pack(f(subcmd, ...)))
	    end
	end)
end)
