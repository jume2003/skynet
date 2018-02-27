--百人牛牛
local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mysocket = require "mysocket"
local StrLink = require "myfunlib.StrLink"
local mjlib = require "myfunlib.base_tips.mjlib"
local utils = require "myfunlib.base_tips.utils"
local tips_lib = require "myfunlib.base_tips.tipslib"

local pm = require "playerctrl"
local tm = require "tablectrl"
local fd_list = {}
local group_list = {}
local group = {}
local CMD = {}
local db

local ret_time = {mode = "brniuniu",cmd = "gametime",info = {}}
local ret_bet = {mode = "brniuniu",cmd = "bet",info = {}}
local ret_jx = {mode = "brniuniu",cmd = "jx",info = {}}
local ret_banlk = {mode = "brniuniu",cmd = "banlk",info = {}}
local ret_sittop4 = {mode = "brniuniu",cmd = "sittop4",info = {}}
local ret_restargame = {mode = "brniuniu",cmd = "restargame",info = {}}

--游戏数据
local game = {mbet={0,0,0,0},zxbet = 0,state= 0,flg= 0,gtime = 0,dtime={5,1,5,15}}
--
local banlk = StrLink
--玩家数据
local player = {}
--
local sit_top4 = {{sex,name,uid,touxian},{sex,name,uid,touxian},{sex,name,uid,touxian},{sex,name,uid,touxian},{sex,name,uid,touxian}}

function banlk:GetBanlkList()
	local banks = self:get()
	local banlklist = {}
	if banks == nil then
		table.insert(banlklist,{name="ststem",uid = 0,coin = tonumber(999999),touxian = 1})
	else
		for i = 1,#banks,1 do
			local user  = pm.get(banks[i])
			if user then
			table.insert(banlklist,{name=user.nick_name,uid = user.uid,coin = tonumber(user.coin),touxian = user.touxian})
			else
			table.insert(banlklist,{name="ststem",uid = 0,coin = tonumber(999999),touxian = 1})
			end
		end
	end

	return banlklist
end

function banlk:IsChangeBanlk()
	local banlklist = self:GetBanlkList()
	local count = #banlklist

	if (banlklist[1].uid == 0 and count >1) then
		return true
	elseif banlklist[1].uid ~= 0 then
		if banlklist[1].coin <1000 then
		return true
		end
	end
	return false
end

function banlk:ChangeBanlk()
	--把第一个庄家删了
	self:pop()
end

function banlk:UpDataSitTop4()
		local stor_list = {}
		for k,v in pairs(fd_list) do
			local user  = pm.getbyfd(v)
			if user then
				table.insert(stor_list,user)  
			end
		end
		table.sort(stor_list,function(a,b)  
			return a.coin<b.coin 
			end )

		for i =1,#stor_list>5 and 5or #stor_list,1 do
		sit_top4[i].sex = stor_list[i].sex
		sit_top4[i].name = stor_list[i].nick_name
		sit_top4[i].uid = stor_list[i].uid
		sit_top4[i].touxian= stor_list[i].touxian
		end
end

function CMD.start(gid)
	--updata users
	game:init()
    skynet.fork(function()
		while true do
			group_list= datacenter.get("group_list")
			group = group_list[gid]
            if group then
			   game:update()
	        end
			skynet.sleep(50)
		end
	end)
    ----游戏倒计时
	skynet.fork(function()
		while true do
			game:sub()
			skynet.sleep(100)
		end
	end)
end

--初始化
function game:init()
	self.gtime = self.dtime[1]
	self.state = 1
	self.flg = 0
end
--倒计时(每秒一次)
function game:sub()
	print("gtime"..self.gtime)
	self.gtime = self.gtime-1
	--时间到了就换游戏状态
	if self.gtime <= 0 then
		self.flg = 0
		self.state = self.state +1
		if self.state >4 then 
			self.state = 1
		end
		self.gtime = self.dtime[self.state]
	end
	--发送游戏时间与游戏状态(所有用户)
	ret_time.info = {gtime = self.gtime,state = self.state}
	mysocket.writebro(fd_list,ret_time)--发送时间
end
--更新在线fd列表
function game:fdupdate()
	fd_list = {}
	for k, v in pairs(group.uids) do
	    local user = pm.get(v)
		if user then
		   table.insert(fd_list,user.fd)
		end
	end
end
--游戏更新
function game:update()	
	self:fdupdate()
	if self.state == 1 and self.flg==0 then--空闲
		for i = 1,#game.mbet,1 do
			self.mbet[i] = 0
		end
		self.zxbet = 0 -- 总下
		self.banlkcoin = 1000--庄家本钱
		player = {}--玩家下注记录

		banlk:UpDataSitTop4()
		ret_sittop4.info = sit_top4
		mysocket.writebro(fd_list,ret_sittop4)
		self.flg = 1
	elseif self.state == 2 and self.flg==0 then--换庄（庄家是系统 or 庄家钱不够 and 上庄列表不为1）
		--发送换庄
		if banlk:IsChangeBanlk() then
			banlk:ChangeBanlk()
			print("换庄")
		end
		local banlklist = banlk:GetBanlkList()
		ret_banlk.info = banlklist
		mysocket.writebro(fd_list,ret_banlk)
		self.flg = 1
	elseif self.state == 3 then--下注
	
	
	elseif self.state == 4 and self.flg == 0 then--开牌
		local card = {{2,3,4,5,6},{7,8,9,2,3},{4,5,6,7,8},{2,3,4,5,6},{2,3,4,5,6}}
		local top3 = {{name,win},{name,win},{name,win}}
		local banlklist = banlk:GetBanlkList()
		local men_wl = {0,0,0,0}--每门胜负
		local banlkwin = 0
		local banlkcoin = 0
		for i = 1,4,1 do
			men_wl[i] = 2--math.random(-3,3)
		end
		--计算
		for k,v in pairs(player) do
			for i = 1,4,1 do
				v.mwin[i] = v.mbet[i]*men_wl[i]
				v.zwin = v.zwin + v.mwin[i]
			end
			banlkwin = banlkwin+(-v.zwin)
			local user = pm.get(k)
			if user then
				user.coin = user.coin + v.zwin
				pm.set(user)
			end
		end

		local stor_list = {}
		for k,v in pairs(player) do
			table.insert(stor_list,v)  
		end
		table.sort(stor_list,function(a,b)  
			return a.zwin<b.zwin 
			end )

		for i =1,#stor_list>3 and 3 or #stor_list,1 do
		top3[i].name = stor_list[i].name
		top3[i].win = stor_list[i].zwin
		end


		if banlklist[1].uid ~= 0 then
			local user = pm.get(banlklist[1].uid)
			user.coin = user.coin+banlkwin
			banlkcoin = user.coin
			pm.set(user)
		else
			banlkcoin = 999999
		end

		for k,v in pairs(fd_list) do
			local user = pm.getbyfd(v)
			if user then
				local pl = player[user.uid]
				local ret_msg = {card = {},top3 = {},mwin = {0,0,0,0},banlkcoin=0,coin = 0,zwin = 0,speed = 1}
				if pl then 
					ret_msg.mwin = pl.mwin
					ret_msg.zwin = pl.zwin
				end
				ret_msg.coin = user.coin
				ret_msg.card = card
				ret_msg.top3 = top3
				ret_msg.banlkwin = banlkwin
				ret_msg.banlkcoin = banlkcoin
				ret_jx.info = ret_msg
				mysocket.write(v,ret_jx)
			end
		end

		self.flg = 1
	end
end
--用户下注
function CMD.bet(msg)
	if game.state == 3 then
		local user = pm.getbyfd(msg.fd)
		local ret_msg = {uid,mid,mbet,zxbet,sybet}
		local banlklist = banlk:GetBanlkList()
		local sybet = (banlklist[1].coin -(game.zxbet + msg.bet))/10
		print("coin "..user.coin)
		if user and sybet>=0 and tostring(user.uid) ~= tostring(banlklist[1].uid) and user.coin >= msg.bet then
			msg.mid = msg.mid %5
			game.zxbet = game.zxbet + msg.bet--总下注
			game.mbet[msg.mid] = game.mbet[msg.mid] + msg.bet--各门总下注
			user.coin = user.coin - msg.bet
			pm.set(user)
			--玩家下注记录
			if player[user.uid] == nil then
				player[user.uid] = {fd = 0,name = "",mbet={0,0,0,0},mwin={0,0,0,0},zwin = 0,zxbet = 0}
			end
			player[user.uid].fd = msg.fd
			player[user.uid].mbet[msg.mid] = player[user.uid].mbet[msg.mid]+msg.bet
			player[user.uid].zxbet = player[user.uid].zxbet + msg.bet
			player[user.uid].name = user.nick_name
			ret_msg.uid = user.uid
			ret_msg.mid = msg.mid
			ret_msg.bet = msg.bet
			ret_msg.coin = user.coin
			ret_msg.mtbet = game.mbet[msg.mid]
			ret_msg.mbet = player[user.uid].mbet[msg.mid]
			ret_msg.zxbet = game.zxbet
			ret_msg.sybet = sybet--剩余下注
			ret_bet.info = ret_msg
			--广播
			mysocket.writebro(fd_list,ret_bet)
		end
	end
end
--用户上庄(空闲时间才可以)
function CMD.addbanlk(msg)
	if game.state == 1 then 
		local user = pm.getbyfd(msg.fd)
		if user then
			--上庄没有满,不存在
			if banlk:getCount()<5 and banlk:finder(user.uid)==nil then
			--上庄成功
			banlk:add(user.uid)
			print(""..user.nick_name.."上庄")
			else
			--已经上庄了
			print(""..user.nick_name.."已经上庄了")
			end
		end
		local banlklist = banlk:GetBanlkList()
		ret_banlk.info = banlklist
		mysocket.write(msg.fd,ret_banlk)
	end
end
--用户下庄(空闲时间才可以)
function CMD.delbanlk(msg)
	if game.state == 1 then 
		local user = pm.getbyfd(msg.fd)
		if user then
			--已存在
			if banlk:finder(user.uid)~=nil then
				--下庄吧
				banlk:del(user.uid)
				print(""..user.nick_name.."下庄")
			else
				--已下庄	 
				print(""..user.nick_name.."已下庄")
			end
		end
		local banlklist = banlk:GetBanlkList()
		ret_banlk.info = banlklist
		mysocket.write(msg.fd,ret_banlk)
	end
	print(banlk.datastr)
end
--
function CMD.restargame(msg)
	print("restargame")
	local banlklist = banlk:GetBanlkList()
	ret_banlk.info = banlklist
	mysocket.write(msg.fd,ret_banlk)

	banlk:UpDataSitTop4()
	ret_sittop4.info = sit_top4
	mysocket.write(msg.fd,ret_sittop4)
	--
	local ret_msg = {mbet = {0,0,0,0},zxbet,sybet}
	ret_msg.mtbet = game.mbet
	ret_msg.zxbet = game.zxbet
	ret_restargame.info = ret_msg
    mysocket.write(msg.fd,ret_restargame)

    if game.state == 4 then
	   ret_jx.info.speed = 0
	   mysocket.write(msg.fd,ret_jx)
	end
end
--
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