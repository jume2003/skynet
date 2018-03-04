--山西扣点点
local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mysocket = require "mysocket"
local mjmrg = require "myfunlib.mjmrg"
local utils = require "myfunlib.base_tips.utils"
local MsgList = require 'MsgList'
local pm = require "playerctrl"
local tm = require "tablectrl"
local mjmrgclone = mjmrg
local comman_msg = MsgList.comman
local fd_list = {}
local group_list = {}
local group = {}
local CMD = {}
local db
--加入游戏
local ret_join = {mode="kddmj",cmd="join",info ={uid = 0,name="",touxian="",sit=0,groupid=0}}
--准备游戏
local ret_ready = {mode="kddmj",cmd="ready",info ={uid = 0,sit = {}}}
--麻将信息
local ret_mjinfo = {mode="kddmj",cmd = "mjinfo",info ={mjinfo={}}}
--坐位信息
local ret_sitinfo = {mode="kddmj",cmd = "sitinfo",info ={user={}}}
--抓位(骰子)
local ret_touzi = {mode="kddmj",cmd="touzi",info ={touzi1 = 0,touzi2=0}}
--赖子
local ret_gui = {mode="kddmj",cmd="gui",info ={gui = 0}}
--分手牌
local ret_handcard = {mode="kddmj",cmd="handcard",info ={cards = {}}}
--抓牌
local ret_catchcard = {mode="kddmj",cmd="catchcard",info ={uid=0,card = 0}}
--出牌
local ret_drawcard = {mode="kddmj",cmd="drawcard",info ={uid = 0,card = 0,index = 0}}
--游戏状态
local ret_gamestate = {mode="kddmj",cmd = "gamestate",info ={state = 0}}
--吃
local ret_eat = {mode="kddmj",cmd="eat",info ={uid = 0,beuid = 0,cards = {0,0,0}}}
--碰
local ret_pen = {mode="kddmj",cmd="pen",info ={uid = 0,beuid = 0,card = 0}}
--暗干
local ret_agan = {mode="kddmj",cmd="agan",info ={uid = 0,card = 0}}
--明干
local ret_mgan = {mode="kddmj",cmd="mgan",info ={uid = 0,beuid = 0,card = 0}}
--听牌
local ret_tip = {mode="kddmj",cmd="tip",info ={uid = 0,card = 0,index = 0}}
--胡牌
local ret_hu = {mode="kddmj",cmd="hu",info ={uid = 0,beuid = 0,card = 0}}
--操作盒子
local ret_crtbox = {mode="kddmj",cmd = "crtbox",info ={}}
--已接收crt请求
local ret_crtreced = {mode="kddmj",cmd = "crtreced",info ={}}
--取消
local ret_pass = {mode="kddmj",cmd="pass",info ={}}
--游戏倒计时
local ret_djshi = {mode="kddmj",cmd="djshi",info ={uids={},djshi_time=0}}
--剩余牌数
local ret_cardcount = {mode="kddmj",cmd="cardcount",info ={count}}
--结算
local ret_jx = {mode="kddmj",cmd = "jx",info ={hutype=0,zfan="",
huid = 0,behuid=0,hucard=0,
gan = {},
user={
	{uid,name,score,hand,men},
	{uid,name,score,hand,men},
	{uid,name,score,hand,men},
	{uid,name,score,hand,men}
	}}}


local game = {gtime = 0,state = 100,is_hang=false,gid=0,jushu = 0,max_djshi=10,gui=5,banlk_uid = 0,crt_uid = 1,sit = {0,0,0,0},card_pile = {}}
--4个玩家
local player_list = {{},{},{},{}}
--玩家对当前出牌操作信息
local sev_crt = {} -- 服务器信息
local cle_crt = {} -- 客户返回信息

function CMD.start(gid)
	--updata users
	game.gid = gid
    skynet.fork(function()
		while true do
			game:fdupdate()
            game:update()
			skynet.sleep(10)
		end
	end)
    ----游戏倒计时
	skynet.fork(function()
		while true do
			if game.state<100 then
				game:sub()
			end
			skynet.sleep(100)
		end
	end)
end

--得到坐位
function game:getsit(uid)
	local sit = 0
	if player_list[uid] then
		sit = player_list[uid].sit
	end
	return sit
end
--得到空闲坐位
function game:getfreesit(uid)
	for i=1,4,1 do
		if tonumber(self.sit[i]) == 0 then
			return i
		end
	end
	return 0
end
--根据坐位得到玩家
function game:getplayerbysit(sit)
	for i=1,4,1 do
		if i == sit then
			local uid = self.sit[i]
			return player_list[uid]
		end
	end
	return nil
end
--根据坐位得到玩家
function game:getplayers()
	local players = {}
	for i=1,4,1 do
		players[i] = self:getplayerbysit(i)
	end
	return players
end
--初始化牌堆
function game:pile_init()
	self.card_pile = {}
	local is_gui = false
	local is_fen = false
	if group.rule.wanfa == 1 then
		--常规玩法
		is_gui = false
		is_fen = true
	elseif group.rule.wanfa == 2 then
		--风耗子
		is_gui = true
		is_fen = true
	elseif group.rule.wanfa == 3 then
		--不带风
		is_gui = false
		is_fen = false
	end
	local mj_count = is_fen and 136 or (136-28)

	for i=1,mj_count,1 do
		local max_mj  = is_fen and 34 or 27
		table.insert(self.card_pile, ((i-1)%max_mj)+1)
	end

	--混乱麻将
	for i=1,mj_count+300,1 do
		local index1 = math.random(1,mj_count)
		local index2 = math.random(1,mj_count)
		local tem = self.card_pile[index1]
		self.card_pile[index1] = self.card_pile[index2]
		self.card_pile[index2] = tem
	end
	--游戏规则
	self.gui = is_gui and math.random(28,34) or 0
end
--创建玩家(坐下)
function game:player_create(user,sit)
	local uid = user.uid
	self.sit[sit] = uid--初始化坐位
	cle_crt[uid] = {uid = uid}
	sev_crt[uid] = {uid = uid}
	player_list[uid] = {}
	player_list[uid] = mjmrg:clone(mjmrgclone)
	player_list[uid].fd = user.fd
	player_list[uid].name = user.nick_name
	player_list[uid].touxian = user.touxian
	player_list[uid].score = 0
	player_list[uid].is_tip = false
	player_list[uid].is_ready = false
	player_list[uid].sit = sit
	player_list[uid].uid = uid
			  		
	print(uid.." sit "..sit)
end
--初始化玩家
function game:player_init(palyer)	
	local cards = {}
	local uid = palyer.uid
	--初始化操作回馈
	cle_crt[uid] = {uid = uid}
	sev_crt[uid] = {uid = uid}
	--初始化玩家手牌
	for i=1,13,1 do
		local card = self.card_pile[#self.card_pile]
		table.remove(self.card_pile,#self.card_pile)
		cards[i] = card
	end
	cards = {1,1,1,1,2,2,2,2,3,3,3,3,4}
	palyer:init(cards,uid)
	
	palyer.is_tip = false
	palyer.is_ready = false
end
--初始化
function game:init()
	--初始化牌堆
	self:pile_init()
	--初始化每一个玩家
	local players = self:getplayers()
	for i=1,4,1 do
		self:player_init(players[i])
	end
	--结算初始化
	self:init_jx()
	--第一局房主坐庄
	if self.jushu == 0 then
		--控牌的uid
		self.banlk_uid = self.sit[1]
	end
	self.crt_uid = self.banlk_uid
	self.jushu = self.jushu+1
	self.gtime = self.max_djshi
	print("主坐庄 "..self.crt_uid)
end
--更新坐位信息
function game:update_sitinfo(uid)
	--每个人的头像，分数，名字，uid,游戏规则,当前局数,剩余牌数
	ret_sitinfo.info.user ={}
	ret_sitinfo.info.rule = group.rule
	ret_sitinfo.info.jushu = self.jushu
	ret_sitinfo.info.myuid = uid
	ret_sitinfo.info.cardcount = #self.card_pile
	ret_sitinfo.info.gui = self.gui
	ret_sitinfo.info.groupid = self.gid
	ret_sitinfo.info.state = self.state
	ret_sitinfo.info.banlk_uid = self.banlk_uid

	local players = self:getplayers()
	for i=1,4,1 do
		if players[i] then
			ret_sitinfo.info.user[i] = {}
			ret_sitinfo.info.user[i].touxian = players[i].touxian
			ret_sitinfo.info.user[i].score = players[i].score
			ret_sitinfo.info.user[i].name = players[i].name
			ret_sitinfo.info.user[i].uid = players[i].uid
			ret_sitinfo.info.user[i].sit = players[i].sit
			ret_sitinfo.info.user[i].is_ready = players[i].is_ready
			ret_sitinfo.info.user[i].is_tip = players[i].is_tip
			ret_sitinfo.info.user[i].uid = players[i].uid
			if uid == players[i].uid then
			   ret_sitinfo.info.mysit = players[i].sit
			end
		else
			ret_sitinfo.info.user[i] = {}
		end
	end
end
--更新麻将信息
function game:update_mjinfo(uid)
	ret_mjinfo.info.user ={}
	local players = self:getplayers()
	ret_mjinfo.info.myuid = uid
	ret_mjinfo.info.banlk_uid = self.banlk_uid
	ret_mjinfo.info.jushu = self.jushu
	for i=1,4,1 do
		local mjinfo = {}
		if players[i] then
			mjinfo.uid = players[i].uid
			--手牌(不是自己的手牌只发个数)
			if uid ~= players[i].uid then
				mjinfo.hand = #players[i].hand
			else
				mjinfo.hand = players[i].hand
			end
			--门前
			mjinfo.men = players[i].men
			--桌面
			mjinfo.disk = players[i].disk
			--坐位
			mjinfo.sit = players[i].sit
			ret_mjinfo.info.mjinfo[i] = mjinfo
			if uid == players[i].uid then
			   ret_mjinfo.info.mysit = players[i].sit
			end
		else
			ret_mjinfo.info.mjinfo[i] = {}
		end
		
	end
end
--倒计时(每秒一次)
function game:sub()
	self.gtime = self.gtime-1
	if self.gtime <=0 then
		self.gtime = 0
	end
	--发送倒计时给要等待的玩家
	local uids = {}
	local players = self:getplayers()
	for i=1,4,1 do
		local uid = players[i].uid
		if (uid~=0 and sev_crt[uid] and 
			cle_crt[uid] and cle_crt[uid].is_ret == false) then
			table.insert(uids,uid)
		end
	end
	ret_djshi.info.uids = uids
	ret_djshi.info.djshi_time = self.gtime
	mysocket.writebro(fd_list,ret_djshi)
end
--更新在线fd列表
function game:fdupdate()
	group_list= datacenter.get("group_list")
	group = group_list[self.gid]
	fd_list = {}
	for k, v in pairs(group.uids) do
	    local user = pm.get(v)
		if user then
		   table.insert(fd_list,user.fd)
		    if player_list[user.uid] then
		  		player_list[user.uid].fd = user.fd
			end
		end
	end
end
--游戏更新
function game:update()	
	if self.is_hang then
		return
	end
	if self.state == 100 then
		if self.jushu >= group.rule.jushu then
    		comman_msg.showbox.info.msg = "游戏结束局数已到"
    		mysocket.writebro(fd_list, comman_msg.showbox)
			--游戏结束局数已到
			self.state = 102
			return
		end
		local players = self:getplayers()
		--机器人默认准备
		for i=1,4,1 do
			if players[i] and players[i].fd<0 then
				players[i].is_ready = true
			end
		end
		--等待玩家准备 要够4个人才可以
		local ready_count = 0
		for i=1,4,1 do
			if players[i] and players[i].is_ready then
				ready_count = ready_count+1
			end
		end
		if ready_count==4 then
			self.state = 101
		end
		--print("wait for palyer:"..#fd_list)
	elseif self.state == 101 then
		self:init()
		self.state = 1
	elseif self.state == 102 then
		--游戏结束局数已到

	elseif self.state == 1 then
		--剩余牌数
		ret_cardcount.info.count = #self.card_pile
		mysocket.writebro(fd_list,ret_cardcount)
		--鬼牌
		ret_gui.info.gui = self.gui
		mysocket.writebro(fd_list,ret_gui)
		--抓位 s
		ret_touzi.info.touzi1 = math.random(1,6)
		ret_touzi.info.touzi2 = math.random(1,6)
		mysocket.writebro(fd_list,ret_touzi)
		skynet.sleep(300)
		--更新房间信息
		for i=1,#self.sit,1 do
			local uid = self.sit[i]
			self:update_mjinfo(uid)
			mysocket.write(player_list[uid].fd,ret_mjinfo)
		end
		skynet.sleep(400)
		self.state = 2
	elseif self.state == 2 then--抓牌
		if #self.card_pile == 0 then
			--流局
			self.state = 6
		else
			--从牌堆中得到一只
			local uid = self.crt_uid
			local gui = self.gui
			if uid ~= 0  then
				local card = self.card_pile[#self.card_pile]
				table.remove(self.card_pile,#self.card_pile)
				print("从牌堆中得到一只"..uid.." "..#self.card_pile)
				self:catchcard(uid,card,gui)	
			end
		end
		ret_cardcount.info.count = #self.card_pile
		mysocket.writebro(fd_list,ret_cardcount)
	elseif self.state == 3 then--发出牌
		local uid = self.crt_uid
		if uid ~= 0  then
			local card = player_list[uid]:getlastdarw()
			local gui = self.gui
			self:drawcard(uid,card,gui)
		end
	elseif self.state == 4 then --吃和碰后的出牌状态
		local uid = self.crt_uid
		local gui = self.gui
		if uid ~= 0  then
			self:afteatpen(uid,gui)
		end
	elseif self.state == 5 then
	--到下一个操作
		local index = self:getsit(self.crt_uid)
		index = index+1
		index = (index-1)%4+1
		self.crt_uid = self.sit[index]
		self.state = 2
	elseif self.state == 6 then
	--广播结算
	print("流局 换庄")
	self:dealjx()
	self:dealnexbanlk()
	mysocket.writebro(fd_list,ret_jx)
	self.state = 100
	skynet.sleep(300)
	end
end
--结算初始化
function game:init_jx()
	ret_jx.info.hutype=0
	ret_jx.info.zfan=""
	ret_jx.info.huid = 0
	ret_jx.info.behuid=0
	ret_jx.info.hucard=0
	ret_jx.info.gan = {}
	ret_jx.info.user={
		{uid,is_ready,name,score,hand,men},
		{uid,is_ready,name,score,hand,men},
		{uid,is_ready,name,score,hand,men},
		{uid,is_ready,name,score,hand,men}
		}
end
--换下一个位做庄
function game:getnexbanlk(uid)
	local nextsit = {2,3,4,1}
	local sit = self:getsit(uid)
	sit = nextsit[sit]
	local next_uid = self.sit[sit]
	return next_uid
end
--换庄处理
function game:dealnexbanlk()
	local banlk_uid = self.banlk_uid
	local huid = ret_jx.info.huid
	local is_gan = #ret_jx.info.gan>0
	if huid == 0 then
		if is_gan then
			banlk_uid = self:getnexbanlk(banlk_uid)
			print("黄局干换下一个位做庄"..banlk_uid)
		else
			banlk_uid = banlk_uid
			print("黄局没干庄家继续坐"..banlk_uid)
		end
	else
		if banlk_uid == huid then
			banlk_uid = huid
			print("庄家胡牌继续坐"..banlk_uid)
		else
			banlk_uid =  self:getnexbanlk(banlk_uid)
			print("换下一个位做庄"..banlk_uid)
		end
	end
	self.banlk_uid = banlk_uid
end
--结算处理
function game:dealjx()
	local huid = ret_jx.info.huid
	local behuid = ret_jx.info.behuid
	local is_zimo =  huid== behuid
	local gui = self.gui
	local card_score = self:getmjscore(ret_jx.info.hucard)
	local is_guihu = ret_jx.info.hucard == self.gui
	local is_zhuang = group.rule.zhuangjia
	local score = {}
	local fantext = {}
	local name = {}
	local user = {}
	for i=1,#self.sit,1 do
		local uid = self.sit[i]
		score[uid] = 0
		fantext[uid] = ""
		user[uid] = pm.get(uid)
	end
	--胡鬼牌(得到最大分牌)
	if is_guihu and huid ~= 0 then
		local tips = player_list[huid]:getpointtips(gui,gui)
		self:kddrule(huid)
		utils.print(tips)
		card_score = 0
		for i=1,#tips,1 do
			if card_score<self:getmjscore(tips[i]) and tips[i] ~= gui then
				card_score = self:getmjscore(tips[i])
			end
		end
	end
	--有人胡牌
	if huid ~= 0 then
	--自摸每人付点数两倍
		if is_zimo then
			for i=1,#self.sit,1 do
				local uid = self.sit[i]
				if uid == huid then
					score[uid] = score[uid]+card_score*2*3
					fantext[uid] = fantext[uid]..string.format("%s自摸(+%d*2*3)",user[huid].nick_name,card_score)
					if is_zhuang then
						score[uid] = score[uid] +20*3
						fantext[uid] = fantext[uid]..string.format("带庄(+20*3)")
					end
				else
					score[uid] = score[uid]-card_score*2
					fantext[uid] = fantext[uid]..string.format("%s自摸(-%d*2)",user[huid].nick_name,card_score)
					if is_zhuang then
						score[uid] = score[uid] -20
						fantext[uid] = fantext[uid]..string.format("带庄(-20)")
					end
				end
			end
		--不是自摸
		else
			local beuid_tip = player_list[behuid].is_tip
			--点炮听牌平分
			if beuid_tip then
				for i=1,#self.sit,1 do
					local uid = self.sit[i]
					if uid == huid then
						score[uid] = score[uid]+card_score*3
						fantext[uid] = fantext[uid]..string.format("%s点炮已听牌(+%d*3)",user[behuid].nick_name,card_score)
						if is_zhuang then
							score[uid] = score[uid] +10*3
							fantext[uid] = fantext[uid]..string.format("带庄(+10*3)")
						end
					else
						score[uid] = score[uid]-card_score
						fantext[uid] = fantext[uid]..string.format("%s点炮已听牌(-%d)",user[behuid].nick_name,card_score)
						if is_zhuang then
							score[uid] = score[uid] -10
							fantext[uid] = fantext[uid]..string.format("带庄(-10)")
						end
					end
				end
			else
				--点炮没听牌一个人输
				score[huid] = score[huid]+card_score*3
				score[behuid] = score[behuid]-card_score*3
				fantext[huid] = fantext[huid]..string.format("%s点炮未听牌(+%d*3)",user[behuid].nick_name,card_score)
				fantext[behuid] = fantext[behuid]..string.format("%s点炮未听牌(-%d*3)",user[behuid].nick_name,card_score)
				if is_zhuang then
					score[huid] = score[huid] +20
					fantext[huid] = fantext[huid]..string.format("带庄(+20)")
					score[behuid] = score[behuid] -20
					fantext[behuid] = fantext[behuid]..string.format("带庄(-20)")
				end
			end
		end
		--特殊牌型 7小对 十三幺 一条龙
		utils.print(cards)
		local htype = player_list[huid]:gethutype(gui)
		if htype ~= 0 then
			local beishu = {2,2,2,4}
			local huname = {"7小对","十三幺","一条龙","豪华7小对"}
			for i=1,#self.sit,1 do
				local uid = self.sit[i]
				score[uid] = score[uid]*beishu[htype]
				fantext[uid] = fantext[uid]..string.format("%s(*%d)",huname[htype],beishu[htype])
			end
		end
		--干牌计分
		utils.print(ret_jx.info.gan)
		for i=1,#ret_jx.info.gan,1 do
			local card = ret_jx.info.gan[i].card
			local ganuid = ret_jx.info.gan[i].uid
			local beuid = ret_jx.info.gan[i].beuid
			local card_score = self:getmjscore(card)
			local is_agan = ganuid == beuid
			local is_guigan = card == self.gui
			if is_guigan then
				for j=1,#self.sit,1 do
					local uid = self.sit[j]
					if uid == ganuid then
						score[uid] = score[uid]+100
						fantext[uid] = fantext[uid]..string.format("%s耗子干(+100)",user[ganuid].nick_name)
					else
						score[uid] = score[uid]-100
						fantext[uid] = fantext[uid]..string.format("%s耗子干(-100)",user[ganuid].nick_name)
					end
				end
			else
					--如果是暗干(每人两倍)
				if is_agan then
					for j=1,#self.sit,1 do
						local uid = self.sit[j]
						if uid == ganuid then
							score[uid] = score[uid]+card_score*2*3
							fantext[uid] = fantext[uid]..string.format("%s暗干(+%d*2*3)",user[ganuid].nick_name,card_score)
						else
							score[uid] = score[uid]-card_score*2
							fantext[uid] = fantext[uid]..string.format("%s暗干(-%d*2)",user[ganuid].nick_name,card_score)
						end
					end
				else
					--明干
					if player_list[beuid].is_tip then
						for j=1,#self.sit,1 do
							local uid = self.sit[j]
							if uid == ganuid then
								score[uid] = score[uid]+card_score*3
								fantext[uid] = fantext[uid]..string.format("%s点干已听牌(+%d*3)",user[beuid].nick_name,card_score)
							else
								score[uid] = score[uid]-card_score
								fantext[uid] = fantext[uid]..string.format("%s点干已听牌(-%d)",user[beuid].nick_name,card_score)
							end
						end
					else
						score[ganuid] = score[ganuid]+card_score*3
						score[behuid] = score[behuid]-card_score*3
						fantext[ganuid] = fantext[ganuid]..string.format("%s点干未听牌(+%d*3)",user[beuid].nick_name,card_score)
						fantext[behuid] = fantext[behuid]..string.format("%s点干未听牌(-%d*3)",user[beuid].nick_name,card_score)
					end
				end
			end
			
		end
		
	else
		--流局
		for i=1,#self.sit,1 do
			local uid = self.sit[i]
			fantext[uid] = "流局"
		end
	end
	

	--更新玩家总分
	for i=1,#self.sit,1 do
		local uid = self.sit[i]
		player_list[uid].score = player_list[uid].score+score[uid]
		player_list[uid].is_ready = false
	end

	ret_jx.info.hutype=1
	ret_jx.info.zfan=""
	for i=1,#self.sit,1 do
		local uid = self.sit[i]
		local user = {uid,touxian,name,score,zscore,hand,men,fantext}
		user.uid = uid
		user.name = player_list[uid].name
		user.hand = player_list[uid].hand
		user.men = player_list[uid].men
		user.score = score[uid]
		user.zscore = player_list[uid].score
		user.fantext = fantext[uid]
		user.touxian = player_list[uid].touxian
		user.is_ready = player_list[uid].is_ready
		user.sit =  player_list[uid].sit
		ret_jx.info.user[i] = user
	end
end
--更新结算
function game:update_jx()
	for i=1,#self.sit,1 do
		local uid = self.sit[i]
		ret_jx.info.user[i].is_ready = player_list[uid].is_ready
	end
end
--效验是否成功
function game:checkcrt(crt)
	-- 默认 0 ,eat 1 ,pen 2, mgan 3 ,agan 4 ,tip 5 ,hu 6 ,drawcard 7 ,取消 8 
	
	local uid = crt.uid
	local ret = false
	if sev_crt[uid] then
		if crt.crt_type==1 then

			if sev_crt[uid].eat then
				for i=1,#sev_crt[uid].eat,1 do
					local eat1 = mjmrg:clone(sev_crt[uid].eat[i])
					local eat2 = mjmrg:clone(crt.cards)
					utils.print(eat1)
					utils.print(eat2)
					--排序
					table.sort(eat1,function(a,b)
						return a>b
					end)
					table.sort(eat2,function(a,b)
						return a>b
					end)
					ret = (eat1[1]==eat2[1] and eat1[2]== eat2[2] and eat1[3]==eat2[3])
					if ret then break end
				end
			else
				ret = false
			end

		elseif crt.crt_type==2  then
			if sev_crt[uid].pen then
				ret = crt.card == sev_crt[uid].pen[1]
			else
				ret = false
			end
		elseif crt.crt_type==3  then
			if sev_crt[uid].mgan then
				ret = crt.card == sev_crt[uid].mgan[1]
			else
				ret = false
			end
		elseif crt.crt_type==4  then
			if sev_crt[uid].agan then
				ret = crt.card == sev_crt[uid].agan[1]
			else
				ret = false
			end
		elseif crt.crt_type==5  then
			ret = sev_crt[uid].tips ~=nil
		elseif crt.crt_type==6  then
			ret = sev_crt[uid].hu ~=nil
		elseif crt.crt_type==7  then
			if sev_crt[uid].drawcard then
				local card = crt.card
				local card_count = player_list[uid]:getcount(card,player_list[uid].hand)
				ret = card_count>0
			else
				ret = false
			end
		elseif crt.crt_type==8  then
			ret = sev_crt[uid].pass ~=nil
		end
	end
	if ret == false then
		print("checkcrt "..tostring(ret).."type"..crt.crt_type)
	end
	return ret
end
--客户返回信息处理
function game:dealcrt(crt)
	-- 默认 0 ,eat 1 ,pen 2, mgan 3 ,agan 4 ,tip 5 ,hu 6 ,drawcard 7 ,取消 8 
	--skynet.call(db, "lua", "dump",crt)
	local crt_type = crt.crt_type
	if crt_type == 1 then
		local uid = crt.uid
		local beuid = self.crt_uid
		player_list[uid]:eat(crt.cards,player_list[beuid])
		ret_eat.info.cards = crt.cards
		ret_eat.info.uid = uid
		ret_eat.info.beuid = beuid
		mysocket.writebro(fd_list,ret_eat)
		ret_gamestate.info.state = 2--发送出牌游戏状态
		mysocket.write(crt.fd,ret_gamestate)
		self.crt_uid = uid
	elseif crt_type == 2 then
		local uid = crt.uid
		local beuid = self.crt_uid
		player_list[uid]:pen(crt.card,player_list[beuid])
		ret_pen.info.card = crt.card
		ret_pen.info.uid = uid
		ret_pen.info.beuid = beuid
		mysocket.writebro(fd_list,ret_pen)
		ret_gamestate.info.state = 2--发送出牌游戏状态
		mysocket.write(crt.fd,ret_gamestate)
		self.crt_uid = uid
	elseif crt_type == 3 then
		local uid = crt.uid
		local beuid = self.crt_uid
		player_list[uid]:mgan(crt.card,player_list[beuid])
		ret_mgan.info.card = crt.card
		ret_mgan.info.uid = uid
		ret_mgan.info.beuid = beuid
		mysocket.writebro(fd_list,ret_mgan)
		mysocket.write(crt.fd,ret_gamestate)
		self.crt_uid = uid
		--结算记录干牌
		table.insert(ret_jx.info.gan,{card=crt.card,uid=uid,beuid=beuid})
	elseif crt_type == 4 then
		local uid = crt.uid
		player_list[uid]:agan(crt.card)
		ret_agan.info.card = crt.card
		ret_agan.info.uid = uid
		mysocket.writebro(fd_list,ret_agan)
			--结算记录干牌
		table.insert(ret_jx.info.gan,{card=crt.card,uid=uid,beuid=uid})
	elseif crt_type == 5 then
		local uid = crt.uid
		player_list[uid].is_tip = true
		ret_tip.info.card = crt.card
		ret_tip.info.index = crt.index
		ret_tip.info.uid = uid
		mysocket.writebro(fd_list,ret_tip)
		player_list[uid]:draw(crt.card)
	elseif crt_type == 6 then
		local uid = crt.uid
		local is_zimo = uid == self.crt_uid
		ret_hu.info.card = crt.card
		ret_hu.info.uid = uid
		ret_hu.info.beuid = self.crt_uid
		--结算记录胡牌
		ret_jx.info.huid = uid
		ret_jx.info.behuid = self.crt_uid
		ret_jx.info.hucard = crt.card
		--不是自摸把牌加到手牌上
		if is_zimo==false then
			--添加到手牌中
			print("adcard "..crt.card)
			player_list[uid]:addcards({[1] = crt.card},1,player_list[uid].hand) 
		end
		mysocket.writebro(fd_list,ret_hu)
	elseif crt_type == 7 then
		ret_drawcard.info.card = crt.card
		ret_drawcard.info.index = crt.index
		ret_drawcard.info.uid = crt.uid
		mysocket.writebro(fd_list,ret_drawcard)
		player_list[crt.uid]:draw(crt.card)
	elseif crt_type == 8 then
	end
	crt.is_ret = false
	return crt_type
end
--听牌后不可以做的事
function game:afttipsnodo(uid,gui)
	--听牌后就不可以再听了,听牌后不能出,听牌后不可以碰吃 只能系统出牌
	if player_list[uid].is_tip and sev_crt[uid] then
		sev_crt[uid].tips = nil
		sev_crt[uid].drawcard = nil
		sev_crt[uid].pen = nil
		sev_crt[uid].eat = nil
		--听牌后如要干牌得要还能听才可以
		if sev_crt[uid].agan or sev_crt[uid].mgan then
			local card =  sev_crt[uid].agan and sev_crt[uid].agan[1] or sev_crt[uid].mgan[1]
			local tips = player_list[uid]:getaftgantips(card,gui)
			if tips ==nil then
				sev_crt[uid].agan = nil
				sev_crt[uid].mgan = nil
			end
		end
		if sev_crt[uid].hu == nil and sev_crt[uid].pen==nil and 
		   sev_crt[uid].mgan==nil and sev_crt[uid].agan==nil 
		   and sev_crt[uid].eat==nil then
      	 sev_crt[uid] = nil
		end
	end
end
--得到麻将点数
function game:getmjscore(card)
	local score = ((card-1)%9)+1
	--风牌10点
	if card >= 28 then
		score = 10
	end
	return score
end
--扣点点规制
function game:kddrule(uid)
	if sev_crt[uid] then
		--胡牌规则
		if sev_crt[uid].hu then
			local score = self:getmjscore(sev_crt[uid].hu.card)
			local is_zimo = uid == self.crt_uid
			if score <= 2 then
				sev_crt[uid].hu = nil
			end
			--自摸3或以上就行--胡别人要6或以上
			if is_zimo==false and score<6 then
				sev_crt[uid].hu = nil
			end
			--没听牌不可以胡
			if player_list[uid].is_tip == false then
				sev_crt[uid].hu = nil
			end
		end
		--听牌规则(小与2点不可听一定要有一个是6或以上)
		if sev_crt[uid].tips then
			local i = 1
			while(i<=#sev_crt[uid].tips) do
				local j = 1
				local is_tip = false 
				while(j<=#sev_crt[uid].tips[i].tips) do
					local card = sev_crt[uid].tips[i].tips[j] 
					local score = self:getmjscore(card)
					if score <=2 then
						table.remove(sev_crt[uid].tips[i].tips,j)
						j = j-1
					elseif score >=6 then
						is_tip = true
					end
					j = j+1
				end

				if is_tip==false then
					table.remove(sev_crt[uid].tips,i)
					i=i-1
				end
				i = i+1
			end
			if #sev_crt[uid].tips <=0 then
				sev_crt[uid].tips = nil
			end
			utils.print(sev_crt[uid].tips)
		end

		if sev_crt[uid].hu == nil and sev_crt[uid].pen==nil and 
		   sev_crt[uid].mgan==nil and sev_crt[uid].eat==nil and
		   sev_crt[uid].tips==nil and sev_crt[uid].agan==nil and 
		   sev_crt[uid].drawcard==nil then
     	   sev_crt[uid] = nil
		end
	end
end
--抓牌逻辑
function game:catchcard(uid,card,gui)
	print("catchcard "..uid)
	local fd = player_list[uid].fd
	--得到此牌本玩家的操作信息
	sev_crt[uid] = player_list[uid]:getcathcrt(card,gui)
	--skynet.call(db, "lua", "dump",player_list[uid].hand)
	--听牌后不可以做的事
	self:afttipsnodo(uid,gui)
	--扣点点规制过虑
	self:kddrule(uid)
	--发抓牌状态 (有待修改 card不要发给其他人)
	ret_catchcard.info.card = card
	ret_catchcard.info.uid = uid
	mysocket.writebro(fd_list,ret_catchcard)
	-- 发送给玩家可操作信息
	ret_crtbox.info = sev_crt[uid]
	mysocket.write(fd,ret_crtbox)
	--发送出牌游戏状态
	ret_gamestate.info.state = 2
	mysocket.write(fd,ret_gamestate)
	--等待玩家回馈
	self.gtime = self.max_djshi
	--听牌后如果不是胡系统自己动出牌
	if player_list[uid].is_tip and  (sev_crt[uid]==nil or 
		(sev_crt[uid].hu==nil and sev_crt[uid].agan==nil))then
		self.gtime = 1
	end

	if fd < 0 then 
		self.gtime = 2
	end
	for k, v in pairs(cle_crt) do
	    v.is_ret = false
	end
	while(true) do
		if cle_crt[uid].is_ret or self.gtime <=0 then
			break;
		end
		skynet.sleep(10)
	end

	local is_moren = false
	if cle_crt[uid].is_ret then
		--处理玩家操作 agan 4 tip 5 hu 6 
		local ret = self:dealcrt(cle_crt[uid])
		--skynet.call(db, "lua", "dump",cle_crt[uid])
		if ret == 4 then--暗干
			self.state = 2
		elseif ret == 5 then--听牌
			self.state = 3
		elseif ret == 6 then--胡牌
			print("catchcard 胡牌")
			self.state = 6
		elseif ret == 7 then--正常出牌
			self.state = 3
		else
			is_moren = true
		end
	else
		is_moren = true
	end
	--超时直接出牌
	if is_moren then
		ret_drawcard.info.card = card
		ret_drawcard.info.index = 0
		ret_drawcard.info.uid = uid
		mysocket.writebro(fd_list,ret_drawcard)
		player_list[uid]:draw(card)
		self.state = 3
	end
end

--出牌逻辑
function game:drawcard(uid,card,gui)
	print("drawcard "..uid)
	--此牌是否可出
	--得到此牌其他玩家的操作信息
	for i=1,#self.sit,1 do
		local uid_tem = self.sit[i]
		sev_crt[uid_tem] = nil
		if uid_tem ~= uid then
			local csit = self:getsit(uid)
			local msit =  self:getsit(uid_tem)
			local nextsit = {2,3,4,1}
			local is_eat = nextsit[csit] == msit--吃的话一定是要当前是上家
			--如果是机器人就不理了
			sev_crt[uid_tem] = player_list[uid_tem]:getdrawcrt(card,gui,is_eat)
			if player_list[uid_tem].fd < 0 then
				sev_crt[uid_tem] = nil
			end
			--听牌后不可以做的事
			self:afttipsnodo(uid_tem,gui)
			--扣点点规制过虑
			self:kddrule(uid_tem)
			--发送操作信息给玩家
			ret_crtbox.info = sev_crt[uid_tem]
			mysocket.write(player_list[uid_tem].fd,ret_crtbox)
		end
	end
	
	--等待玩家回馈
	self.gtime = self.max_djshi
	--skynet.call(db, "lua", "dump",sev_crt[1])
	for k, v in pairs(cle_crt) do
	    v.is_ret = false
	end
	while(true) do 
	 --如果所有的返回
	 local is_ret_all = true
	 for i=1,#self.sit,1 do
		local uid_tem = self.sit[i]
		if (sev_crt[uid_tem] and uid_tem ~= uid and cle_crt[uid_tem].is_ret == false) then
			is_ret_all = false
		end
	 end
	 if is_ret_all or self.gtime<=0 then
		break
	 end
	 skynet.sleep(10)
	end
	--默认 0 ,eat 1 ,pen 2, mgan 3 ,agan 4 ,tip 5 ,hu 6 ,drawcard 7 ,取消 8
	--排序返回的cle_crt按权重(过,吃，碰，干，胡)
	local clecrt_tem = {}
	for k, v in pairs(cle_crt) do
		if v and v.is_ret then
	   		clecrt_tem[#clecrt_tem+1] = v
		end
	end

	table.sort(clecrt_tem,function(a,b)
		local qu = {a.crt_type,b.crt_type}
		if qu[1] == 8 then
			qu[1] = 0
		end
		if qu[2] == 8 then
			qu[2] = 0
		end
		return qu[1] > qu[2]
	end)
	

	--得到权生最大那个
	local crt_tem = clecrt_tem[1] 
	--处理crt操作
	local is_moren = false
	--is_ret为true
	if crt_tem  and crt_tem.is_ret then
		--处理玩家操作 eat 1 pen 2 mgan 3 hu 6 
		local ret = self:dealcrt(crt_tem)
		if ret == 1 then--吃
			self.state = 4
		elseif ret ==2 then--碰
			self.state = 4
		elseif ret == 3 then--明干
			self.state = 2
		elseif ret == 6 then--胡牌
			print("drawcard 胡牌")
			self.state = 6
		else
			is_moren = true
		end
	else
		is_moren = true
	end
	
	if is_moren then
		self.state = 5
	end
end
--吃碰后逻辑
function game:afteatpen(uid,gui)
	print("afteatpen")
	--得到此牌本玩家的操作信息
	sev_crt[uid] = player_list[uid]:getafteatpen(gui)
	--扣点点规制过虑
	self:kddrule(uid)
	--发送操作信息给玩家
	ret_crtbox.info = sev_crt[uid]
	mysocket.write(player_list[uid].fd,ret_crtbox)
	--等待玩家回馈
	self.gtime = self.max_djshi
	for k, v in pairs(cle_crt) do
	    v.is_ret = false
	end
	while(true) do
		if cle_crt[uid].is_ret or self.gtime <=0 then
			break;
		end
		skynet.sleep(10)
	end

	local is_moren = false
	if cle_crt[uid].is_ret then
		--处理玩家操作 agan 4 tip 5 hu 6 
		local ret = self:dealcrt(cle_crt[uid])
		if ret == 5 then--听牌
			self.state = 3
		elseif ret == 7 then--正常出牌
			self.state = 3
		else
			is_moren = true
		end
	else
		is_moren = true
	end
	--超时直接出牌
	if is_moren then
		--吃碰后默认出牌需要排序
		table.sort(player_list[uid].hand,function(a,b)
			return a<b
		end)
		local card = player_list[uid].hand[#player_list[uid].hand]
		ret_drawcard.info.card = card
		ret_drawcard.info.index = 0
		ret_drawcard.info.uid = uid
		mysocket.writebro(fd_list,ret_drawcard)
		player_list[uid]:draw(card)
		self.state = 3
	end
end
--玩家返回操作

--玩家吃牌{eats = {1,2,3}}
function CMD.eat(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		--效验是否成功
		msg.uid = user.uid
		if game:checkcrt(msg) then
			cle_crt[user.uid] = msg
			cle_crt[user.uid].fd = msg.fd
			cle_crt[user.uid].is_ret = true
		end
		mysocket.write(msg.fd,ret_crtreced)
	end
end
--玩家碰牌{pen=0}
function CMD.pen(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		--效验是否成功
		msg.uid = user.uid
		if game:checkcrt(msg) then
			cle_crt[user.uid] = msg
			cle_crt[user.uid].fd = msg.fd
			cle_crt[user.uid].is_ret = true
		end
		mysocket.write(msg.fd,ret_crtreced)
	end
end
--玩家明干{mgan=0}
function CMD.mgan(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		--效验是否成功
		msg.uid = user.uid
		if game:checkcrt(msg) then
			cle_crt[user.uid] = msg
			cle_crt[user.uid].fd = msg.fd
			cle_crt[user.uid].is_ret = true
		end
		mysocket.write(msg.fd,ret_crtreced)
	end
end

--玩家暗干{agan=0}
function CMD.agan(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		--效验是否成功
		msg.uid = user.uid
		if game:checkcrt(msg) then
			cle_crt[user.uid] = msg
			cle_crt[user.uid].fd = msg.fd
			cle_crt[user.uid].is_ret = true
		end
		mysocket.write(msg.fd,ret_crtreced)
	end
end

--玩家听牌
function CMD.tip(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		--效验是否成功
		msg.uid = user.uid
		if game:checkcrt(msg) then
			cle_crt[user.uid] = msg
			cle_crt[user.uid].fd = msg.fd
			cle_crt[user.uid].is_ret = true
		end
		mysocket.write(msg.fd,ret_crtreced)
	end
end
--玩家胡牌{hu = true}
function CMD.hu(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		--效验是否成功
		msg.uid = user.uid
		if game:checkcrt(msg) then
			cle_crt[user.uid] = msg
			cle_crt[user.uid].fd = msg.fd
			cle_crt[user.uid].is_ret = true
		end
		mysocket.write(msg.fd,ret_crtreced)
	end
end
--取消
function CMD.pass(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		--效验是否成功
		msg.uid = user.uid
		if game:checkcrt(msg) then
			cle_crt[user.uid] = msg
			cle_crt[user.uid].fd = msg.fd
			cle_crt[user.uid].is_ret = true
		end
		mysocket.write(msg.fd,ret_crtreced)
	end
end
--玩家正常出牌{drawcard = 0}
function CMD.drawcard(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		--效验是否成功
		msg.uid = user.uid
		if game:checkcrt(msg) then
			cle_crt[user.uid] = msg
			cle_crt[user.uid].fd = msg.fd
			cle_crt[user.uid].is_ret = true
		end
	end
end
--玩家退出
function CMD.exit_group(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		local sit = game:getsit(user.uid)
		game.sit[sit] = 0
		player_list[user.uid] = nil
	end
end
--游戏状态
function CMD.game_state(msg)
	return game.state
end
--是否挂起游戏
function CMD.game_hang(is_hang)
	game.is_hang = is_hang
end
--准备游戏
function CMD.ready(msg)
	local user = pm.getbyfd(msg.fd)
	if user then
		player_list[user.uid].is_ready = true
		ret_ready.info.sit = player_list[user.uid].sit
		mysocket.writebro(fd_list,ret_ready)
	end
end
--进入房间
function CMD.join(msg)
	game:fdupdate()
	utils.print(fd_list)
	local user = pm.getbyfd(msg.fd)
	if user then
		local sit = game:getfreesit()
		utils.print(game.sit)
		if sit ~= 0 then
			game:player_create(user,sit)
			local players = game:getplayers()
				for i=1,4,1 do 
					if players[i] then
						game:update_sitinfo(players[i].uid)
						mysocket.write(players[i].fd,ret_sitinfo)
					end
				end
			return true
		end
	end
	return false
end
--恢复游戏
function CMD.resgame(msg)
	game:fdupdate()
	local user = pm.getbyfd(msg.fd)
	if user and player_list[user.uid] then
		game:update_sitinfo(user.uid)
		game:update_mjinfo(user.uid)
		mysocket.write(msg.fd,ret_sitinfo)	
		--游戏等待状态
		if game.state >= 100 then
			if game.jushu > 0  then
				game:update_jx()
				mysocket.write(msg.fd,ret_mjinfo)
				mysocket.write(msg.fd,ret_jx)
			end
		else
		--游戏开始状态
			mysocket.write(msg.fd,ret_mjinfo)
		end
	end
end

function CMD.disconnect()
  -- todo: do something before exit
  if game.jushu == 0 then
  		--房费退还
  		local fanfei = {1,2}
	    local needfanfei = fanfei[group.rule.fanfei]
	    local user = pm.get(group.fzuid)
	  	user.card = user.card+needfanfei
	    pm.set(user)
  end
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