local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local utils = require "myfunlib.base_tips.utils"
local mjmrg = {hand = {},disk = {},men={eat={},pen={},gan={}},is_tip=false,fd=0,gl_ser = nil}
--正常牌
function mjmrg:isnormalcard(card)
	local ret = card>=1 and card <=34
		if ret == false then
			print("not normalcard! card:"..card)
			utils.print(self.hand)
		end
	return ret
end
--
function mjmrg:isnormalpile(cards)
	for i=1,#cards,1 do
		if cards[i] <0 or cards[i]>4 then
			print("not normalpile!")
			utils.print(cards)
			return false
		end
	end
	return true
end
--makecards
function mjmrg:makecards(hcards,card)
	local cards = {
			0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0,0,0,
			0,0,0,0,0,0,0
		}	
	for i=1,#hcards,1 do
		if self:isnormalcard(hcards[i]) then
		cards[hcards[i]] = cards[hcards[i]]+1
		end
	end
	if card then
		if self:isnormalcard(card) then
			cards[card] = cards[card]+1
		end
	end
	if self:isnormalpile(cards) then
		return cards
	end
	return nil
end
--makecolorcards
function mjmrg:makecolorcards(hcards)
	local colors = {{},{},{},{}}
	for i=1,#hcards,1 do
		if self:isnormalcard(hcards[i]) then
			local color = math.modf((hcards[i]-1)/9) + 1
			local card = (hcards[i]-1)%9+1
			colors[color][card] = colors[color][card]+1
		end
	end
	return colors
end
--得到花色
function mjmrg:getcolor(card)
	local color = math.modf((card-1)/9) + 1
	return color
end

--得到最后一次出的牌
function mjmrg:getlastdarw()
	local card = 0
	if #self.disk > 0 then
		card = tonumber(self.disk[#self.disk])
	end
	return card
end
--桌子最后一个删掉
function mjmrg:dellastdarw()
	if #self.disk > 0 then
	table.remove(self.disk,#self.disk)
	return true
	end
	return false
end
--删除指定牌在组中的个数
function mjmrg:delcard(card,delcount,cards)
	local count = 0
	local index = 1
	while(cards[index]) do
		if tonumber(card) == tonumber(cards[index]) then
			table.remove(cards,index)
			count = count+1
			index = 0
			if count == delcount then
			return true
			end
		end
		index = index+1
	end
	return count == delcount
end
--指定牌在组中添加
function mjmrg:addcards(addcards,count,cards)
	for i =1,count,1 do 
		for j =1,#addcards,1 do
			cards[#cards+1] = addcards[j]
		end
	end
	--排序
end
--得到指定牌在组中的个数
function mjmrg:getcount(card,cards)
	local count = 0
	for i=1,#cards,1 do
		if tonumber(card) == tonumber(cards[i]) then
		count = count+1
		end
	end
	return count
end
--初始化卡牌
function mjmrg:init(cards)
	self.hand = {}--手牌
	self.disk = {}--桌面
	self.men={eat={},pen={},gan={}}--门前
	self.hand = cards
	self.gl_ser = datacenter.get("gl")
end
--明干牌（干别人）
function mjmrg:mgan(card,otmj)
	--手牌中是否存在指定牌3个
	local count = self:getcount(card,self.hand)
	--别人最后出的是否指定牌
	local last = otmj:getlastdarw()
	if count == 3 and last == card then
		--把别人桌子最后一个删掉
		otmj:dellastdarw()
		--把自己手牌中3个删掉
		self:delcard(card,3,self.hand)
		--在自己的门前加4个到干牌组
		self:addcards({[1]=card},4,self.men.gan)
		return true
	end
	return false
end
--暗干
function mjmrg:agan(card)
	--utils.print(self.hand)
	--手牌与门前加起是否有4个
	local hcount = self:getcount(card,self.hand)
	local mcount = self:getcount(card,self.men.pen)
	local ret = false
	if hcount+mcount == 4 then
		--把手牌中的此牌删除
		self:delcard(card,4,self.hand)
		--添加到门前
		self:addcards({[1]=card},4,self.men.gan)
		ret = true
	end
	--utils.print(self.hand)
	return ret
end
--碰牌
function mjmrg:pen(card,otmj)
	--手牌中是否有两个或以上
	--utils.print(self.hand)
	local hcount = self:getcount(card,self.hand)
	--别人最后出的是否指定牌
	local last = otmj:getlastdarw()
	if hcount >= 2 and last == card then
		--把手牌中的此牌删除2个
		self:delcard(card,2,self.hand)
		--把别人桌子最后一个删掉
		otmj:dellastdarw()
		--添加到门前
		self:addcards({[1]=card},3,self.men.pen)

		--utils.print(self.hand)
		return true
	end
	return false
end
--吃牌(cards {别人的，我的，我的})
function mjmrg:eat(cards,otmj)
	--print("eat "..#self.hand)
	--utils.print(self.hand)
	--手牌中是否有两个或以上
	if cards and #cards == 3 then
		local count1 = self:getcount(cards[2],self.hand)
		local count2 = self:getcount(cards[3],self.hand)
		--别人最后出的是否指定牌
		local last = otmj:getlastdarw()
		if count1~=0 and count2~=0 and last == cards[1] then
			--把手牌中的此牌删除2个
			self:delcard(cards[2],1,self.hand)
			self:delcard(cards[3],1,self.hand)
			--把别人桌子最后一个删掉
			otmj:dellastdarw()
			--print("eat end"..#self.hand)
			--utils.print(self.hand)
			--添加到门前
			self:addcards(cards,1,self.men.eat)
			return true
		end
	end
	
	return  false
end
--出牌
function mjmrg:draw(card)
	--print("draw "..#self.hand)
	local ret = self:delcard(card,1,self.hand)
	if ret == false then
		print("出牌错误 "..card)
		utils.print(self.hand)
	end
	self:addcards({card},1,self.disk)
	--print("draw end"..#self.hand)
	return crt_info
end
--得到干牌后是否还可以听(是一个拷贝不影响hand)
function mjmrg:getaftgantips(card,gui)
	local tip_goup = {}
	local pass_card = {}
	local handclone = mjmrg:clone(self.hand)
	--把干牌从手从删了
	self:delcard(card,4,handclone)
	--print("getaftgantips "..#handclone)
	--utils.print(handclone)

	if #handclone > 2 then
		local cards = self:makecards(handclone)
		if cards and #cards > 2 then
			local tips = skynet.call(self.gl_ser, "lua", "get_tips",cards,gui)
			if #tips >0 then	
				table.insert(tip_goup,{card = 0,tips = tips})
			end
		end
	elseif #handclone == 1 then
		--只有两只牌时就是胡其中一只
		local card1 = handclone[1]
		table.insert(tip_goup,{card =card1,tips = {card1}})
	end
	
	if #tip_goup == 0 then
		tip_goup = nil
	end
	return tip_goup
end
--得到删指定牌得到的听牌
function mjmrg:getpointtips(card,gui)
	local tips= {}
	if #self.hand > 1 then
		local cards = self:makecards(self.hand)
		--删指定
		cards[card] = cards[card]-1
		if cards[card]<0 then
			cards[card]=0
		end
		if cards and #cards > 1 then
			tips = skynet.call(self.gl_ser, "lua", "get_tips",cards,gui)
			
			local added_tips = {}
			if #tips >0 then
			--去重
				local newtips = {}
				for i=1,#tips,1 do
					if added_tips[tips[i]] == nil then
						added_tips[tips[i]] = {}
						newtips[#newtips+1] = tips[i]
					end
				end	
				tips = newtips
			end
		end	
	elseif #self.hand == 1 then
		--只有两只牌时就是胡其中一只
		local card1 = self.hand[1]
		table.insert(tips,card1)
	end
	if #tips == 0 then
		tips = nil
	end
	return tips
end
--得到听牌信息
function mjmrg:gettips(gui)
	local tip_goup = {}
	local pass_card = {}
	print("gettips "..#self.hand)
	utils.print(self.hand)
	if #self.hand > 2 then
		for i = 1,#self.hand,1 do 
			local hand_tem = {}
			local is_pass = false
			for j =1,#pass_card,1 do
				if pass_card[i] == self.hand[i] then
					is_pass = true
					break
				end
			end
			if is_pass == false then
				pass_card[#pass_card+1]=self.hand[i]
				--做一个备份
				hand_tem = self:clone(self.hand)
				pass_card[#pass_card+1] = hand_tem[i]
				--把第i个删了
				table.remove(hand_tem,i)
				local cards = self:makecards(hand_tem)
				if cards and #cards > 2 then
					--print("tips "..i)
					--utils.print(cards)
					local tips = skynet.call(self.gl_ser, "lua", "get_tips",cards,gui)
					local added_tips = {}
					if #tips >0 then
						--去重
						local newtips = {}
						for i=1,#tips,1 do
							if added_tips[tips[i]] == nil then
								added_tips[tips[i]] = {}
								newtips[#newtips+1] = tips[i]
							end
						end	
						tips = newtips
						table.insert(tip_goup,{card =self.hand[i],tips = tips})
					end
				end
			end		
		end
	elseif #self.hand == 2 then
		--只有两只牌时就是胡其中一只
		local card1 = self.hand[1]
		local card2 = self.hand[2]
		table.insert(tip_goup,{card =card1,tips = {card2}})
		table.insert(tip_goup,{card =card2,tips = {card1}})

	end
	

	if #tip_goup == 0 then
		tip_goup = nil
	end
	return tip_goup
end
--得到暗干信息
function mjmrg:getagan()
	--暗干（手牌1只 门前碰3只）
	local aganifo = {}
	local hcards = self:makecards(self.hand)
	local mcards = self:makecards(self.men.pen)
	if hcards and mcards then
		for i=1,#hcards,1 do
			hcards[i] = hcards[i]+mcards[i]
			if hcards[i] == 4 then
				table.insert(aganifo,i)
			end
		end
	end

	if #aganifo == 0 then
		aganifo = nil
	end
	return aganifo
end
--得到明干信息
function mjmrg:getmgan(card)
	local mganifo = {}
	local count = self:getcount(card,self.hand)
	if count == 3 then
		table.insert(mganifo,card)
	end
	if #mganifo == 0 then
		mganifo = nil
	end
	return mganifo
end
--得到吃牌信息
function mjmrg:geteat(card)
	--print("geteat "..card)
	local eatifo = {}
	local hcards = self:makecards(self.hand)
	--不是风牌
	if card <28 and hcards then
		local cards = {0,0,0}
		local crtay = {{1,2},{-1,1},{-1,-2}}
		cards[1] = card
		local color = self:getcolor(card)
		for i =1,3,1 do
			cards[2] = card+crtay[i][1]
			cards[3] = card+crtay[i][2]
			if cards[2]>=1 and cards[3]>=1 and hcards[cards[2]]>0 and hcards[cards[3]]>0 then
				if color==self:getcolor(cards[2]) and
				   color==self:getcolor(cards[3]) then
				--utils.print(cards)
				table.insert(eatifo,self:clone(cards))
				--utils.print(eatifo)
				end
			end
		end
	end

	if #eatifo == 0 then
		eatifo = nil
	end
	return eatifo
end
--得到碰牌信息
function mjmrg:getpen(card)
	local penifo = {}
	local count = self:getcount(card,self.hand)
	if count >= 2 then
		table.insert(penifo,card)
		--print("insert "..count.."card"..card)
	end
	--得到手牌中是否有两个
	if #penifo == 0 then
		penifo = nil
	end
	return penifo
end
--是否可以湖牌
function mjmrg:check_hu(card,gui)
	local cards = self:makecards(self.hand)
	local ret_hu = false
	if cards then
		if card and self:isnormalcard(card) then
			cards[card] = cards[card]+1
		end
		if self:isnormalpile(cards) then
			ret_hu = skynet.call(self.gl_ser, "lua", "get_hu_info",cards,gui)
		end
	end
	return ret_hu
end
--得到湖牌信息
function mjmrg:gethu(card,gui)
	local huifo = {hu=true,card = card}
	local ret_hu = self:check_hu(card,gui)
	if ret_hu == false then
		huifo = nil
	end
	return huifo
end
--得到湖牌牌型
function mjmrg:gethutype(gui)
	local cards = self:makecards(self.hand)
	local htype = 0
	if cards and #cards > 2 then
		htype = skynet.call(self.gl_ser, "lua", "get_hutype",cards,gui)
	end
	return htype
end
--得到抓牌可操作信息(随便添加到手牌中)
function mjmrg:getcathcrt(card,gui)
	--print("getcathcrt "..card)
	--抓牌可以出牌
	local crt_info = {agan,tips,hu,drawcard=0,pass=0}
	--抓牌操作信息(听,自摸,暗干)
	--print("getcathcrt1")
	crt_info.hu = self:gethu(card,gui)
	--添加到手牌中
	self:addcards({[1] = card},1,self.hand)
	--print("getcathcrt2")
	crt_info.tips = self:gettips(gui)
	--print("getcathcrt3")
	crt_info.agan = self:getagan()
	--print("endgetcathcrt ")
	--if crt_info.hu == nil and crt_info.tips==nil and crt_info.agan==nil then
       --crt_info = nil
	--end
	if crt_info then
		--utils.print(self.hand)
	end
	return crt_info
end
--得到出牌可操作信息
function mjmrg:getdrawcrt(card,gui,is_eat)
	--print("getdrawcrt "..card)
	--utils.print(self.hand)
	local crt_info = {eat,pen,mgan,hu,pass=0}
	--抓牌操作信息(听,自摸,暗干)
	--print("getdrawcrt0")
	crt_info.hu = self:gethu(card,gui)
	--print("getdrawcrt1")
	crt_info.pen = self:getpen(card)
	--print("getdrawcrt2")
	crt_info.mgan = self:getmgan(card)
	--print("getdrawcrt3")
	crt_info.eat = is_eat and self:geteat(card) or nil
	--print("endgetdrawcrt")
	if crt_info.hu == nil and crt_info.pen==nil and crt_info.mgan==nil and crt_info.eat==nil then
       crt_info = nil
	end
	if crt_info then
		--utils.print(self.hand)
	end
	return crt_info
end
--得到吃碰后的可操作信息
function mjmrg:getafteatpen(gui)
	--print("getafteatpen")
	--utils.print(self.hand)
	local crt_info = {tips,drawcard=0}
	crt_info.tips = self:gettips(gui)
	return crt_info
end
--克隆
function mjmrg:clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end
return mjmrg