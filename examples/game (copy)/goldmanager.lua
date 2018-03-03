local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mysocket = require "mysocket"
local utils = require "myfunlib.base_tips.utils"
local hulib = require "myfunlib.gui_table.hulib"
local hutype = require "myfunlib.gui_table.hutype"
local table_mgr = require "myfunlib.gui_table.table_mgr"

local CMD = {}
local gold_list = {}
--
function CMD.get_gold(name)
  print("get_gold" ..name)
  print(gold_list[name])
  return  gold_list[name]
end

function CMD.get_hu_info(cards, gui_index)
  return  hulib.get_hu_info(cards, gui_index)
end

function CMD.get_tips(cards, gui_index)
  return  hulib.get_tips(cards, gui_index)
end

function CMD.get_hutype(cards, gui_index)
  --特殊牌型
  local hand_cards = {}
    for i,v in ipairs(cards) do
        hand_cards[i] = v
    end

    local gui_num = 0
    if gui_index > 0 then
        gui_num = hand_cards[gui_index]
        hand_cards[gui_index] = 0
    end
  --7小对
  local is_7dui = hutype.is_7_dui(hand_cards,gui_num)
  --十三幺
  local is_13yao = hutype.is_13_19(hand_cards,gui_num)
  --一条龙
  local is_ytl = hutype.is_qing_yi_se(hand_cards,gui_num)
  local htype = {is_7dui,is_13yao,is_ytl}
  local htype_index = 0
  for i=1,#htype,1 do 
    if htype[i] then
      htype_index = i
    end
  end
  return htype_index
end

skynet.start(function()
	db = datacenter.get("db")
 --加载胡牌数据
  table_mgr:init()
  table_mgr:load()

	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = CMD[cmd]
		if f then
		   skynet.ret(skynet.pack(f(subcmd, ...)))
	    end
	end)
end)
