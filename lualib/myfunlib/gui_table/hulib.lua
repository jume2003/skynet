local table_mgr = require "myfunlib.gui_table.table_mgr"
local hutype = require "myfunlib.gui_table.hutype"
local datacenter = require "skynet.datacenter"
local M = {}

function M.get_hu_info(cards, gui_index)
    local hand_cards = {}
    for i,v in ipairs(cards) do
        hand_cards[i] = v
    end

    local gui_num = 0
    if gui_index > 0 then
        gui_num = hand_cards[gui_index]
        hand_cards[gui_index] = 0
    end
	--特殊牌型
	  --7小对
	  local is_7dui = hutype.is_7_dui(hand_cards,gui_num)
	  --十三幺
	  local is_13yao = hutype.is_13_19(hand_cards,gui_num)

    return M.check(hand_cards, gui_num) or is_7dui or is_13yao
end

function M.get_tips(cards, gui_index)
	local tips = {}
	for i=1,34,1 do
		cards[i]=cards[i]+1
		if M.get_hu_info(cards,gui_index) then
			table.insert(tips,i)
		end
		cards[i]=cards[i]-1
	end
	return tips
end

function M.check(cards, gui_num)
	local total_need_gui = 0
	local eye_num = 0
	for i=0,3 do
		local from = i*9 + 1
		local to = from + 8
		if i == 3 then
			to = from + 6
		end
		
		local need_gui, eye = M.get_need_gui(cards, from, to, i<3, gui_num)
		if not need_gui then
		    return false
		end
		total_need_gui = total_need_gui + need_gui
		if eye then
			eye_num = eye_num + 1
		end
	end
	
	if eye_num == 0 then
		return total_need_gui + 2 <= gui_num
	elseif eye_num == 1 then
		return total_need_gui <= gui_num
	else
		return total_need_gui + eye_num - 1 <= gui_num
	end
end

function M.get_need_gui(cards, from, to, chi, gui_num)
	local num = 0
	local key = 0
	for i=from,to do
		key = key * 10 + cards[i]
		num = num + cards[i]
	end
	
	if num == 0 then
	    return 0, false
	end

    for i=0, gui_num do
        local yu = (num + i)%3
        if yu ~= 1 then
            local eye = (yu == 2)
            if table_mgr:check(key, i, eye, chi) then
                return i, eye
            end
        end
    end
end


return M
