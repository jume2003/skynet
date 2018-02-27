local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mysocket = require "mysocket"
local pm = require "playerctrl"
local tm = require "tablectrl"
local fd_list = {}
local group_list = {}
local group = {}
local CMD = {}
local db
--gamedata
local cur_time = 0--当前时间
local kx_time = 5--空闲时间
local bet_time = 15--下注时间
local open_time = 20--开牌时间
local state = 0--游戏状态(0 空闲 1下注 2开牌)
cur_time = kx_time
--返回消息

--玩家下注
local ret_bet = {mode = "niuniu",cmd = "bet",info = {uid= 0,bet = 0,place = 0,tya = 0,mya = 0,ttya = 0,syya = 0,lzs = 0}}
--上庄列表
local ret_banlk = {names = {"1","2","3","4","5"}}
--结算
local ret_jx = {mode = "niuniu",cmd = "jx",info ={
users={
{name,win,card={1,2,3,4,5}},
{name,win,card={1,2,3,4,5}},
{win,card={1,2,3,4,5}},
{win,card={1,2,3,4,5}},
{win,card={1,2,3,4,5}},
{win,card={1,2,3,4,5}}
},
top={mode = "niuniu",name={"1","2","3","4","5"},win={1,2,3,4,5}}
}
}
--倒计时
local ret_time = {mode = "niuniu",cmd = "gametime",info = {state = 0,time = 123}}
--游戏场景
local ret_resgame = {state,jx,bets,cars,time}

function CMD.start(gid)
	--updata users
    skynet.fork(function()
		while true do
			group_list= datacenter.get("group_list")
			group = group_list[gid]
			print(gid.." niuniu run")
			--skynet.call(db, "lua", "dump",group)
            if group then
			   game_update()
	        end
			skynet.sleep(50)
		end
	end)
    ----游戏倒计时
	skynet.fork(function()
		while true do
			cur_time = cur_time-1
			ret_time.info.state = state
			ret_time.info.time = cur_time
	        mysocket.writebro(fd_list,ret_time)--发送时间
			if cur_time<=0 then
			cur_time = 0
			end
			skynet.sleep(50)
		end
	end)
end
--游戏更新
function game_update()
	--更新在线fd列表
	fd_list = {}
	for k, v in pairs(group.uids) do
	    local user = pm.get(v)
		if user then
		   table.insert(fd_list,user.fd)
		end
	end
	----游戏逻辑
	if state == 0 then
    	if cur_time == 0 then
   		state = 1
   		cur_time = bet_time
   		end
	elseif state == 1 then
  		if cur_time == 0 then
  		state = 2
  		--发送结算
  		for i =1,5,1 do
			for j =1,5,1 do
			ret_jx.info.users[i].card[j] = math.random(1,5)
			end
		end
   		mysocket.writebro(fd_list,ret_jx)
   		cur_time = open_time
   		end
	elseif state == 2 then
   		if cur_time == 0 then
   		
   		--是否换庄
   		state = 0
   		cur_time = kx_time
   		end
   	else
	end
end	
--下注
function CMD.bet(msg)
	--是否下注时间
	if state == 1 then
		local user = pm.getbyfd(msg.fd)
		if user then
		--是否足够金币
		--发送广播

		msg.uid = user.uid
		ret_bet.info = msg
		ret_bet.info.tya = 10000
		ret_bet.info.mya = 100
		ret_bet.info.ttya = 10100
		ret_bet.info.syya = 1000000
		ret_bet.info.lzs = 10
	    mysocket.writebro(fd_list,ret_bet)
		end
	end
end


function CMD.disconnect()
  -- todo: do something before exit
  skynet.exit()
end

skynet.start(function()
  db = datacenter.get("db")
  pm.init(datacenter.get("pm"))
  tm.init(datacenter.get("tm"))
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = CMD[cmd]
		if f then
		   skynet.ret(skynet.pack(f(subcmd, ...)))
	    end
	end)
end)
