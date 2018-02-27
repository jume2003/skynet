local utils = require "myfunlib.base_tips.utils"
local M = {}

-- 是否七对
function M.is_7_dui(cards,gui_num)
    local sum = 0
    local need_gui = 0
    for i,v in ipairs(cards) do
        sum = sum + v
        if v == 1 or v == 3 then
            need_gui = need_gui + 1
        end 
    end
    return sum + gui_num == 14 and gui_num >= need_gui
end

-- 判断十三幺(东西南北中发白，1万9万1筒9筒1条9条全齐)
function M.is_13_19(cards,gui_num)
    local sum = 0
    local tbl_13_1_9 = {1,9,10,18,19,27,28,29,30,31,32,33,34}
    local eye = 0
    for _, i in ipairs(tbl_13_1_9) do
        local c = cards[i]
        if c ~= 0 and c ~= 1 and c~=2 then
            return false
        end
        if c == 2 then
            eye = eye+1
        end
        if eye >=2 then
            return false
        end
        sum = sum + c
    end
    return sum +gui_num== 14
end

-- 检查单调(扣除一对当前牌，能组成顺子各刻子的组合，则为单调)
function M.is_qing_yi_se(cards,gui_num)
    local colors = {0,0,0,0}
    for i,v in pairs(cards) do
        if v > 0 then
            local color = math.floor((i-1)/9) + 1
            colors[color] = 1
        end
    end

    return false--colors[1] + colors[2] + colors[3] + colors[4] == 1
end

return M