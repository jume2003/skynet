--字符串链表
local StrLink = {datastr=""}
--字符串分割函数
--传入字符串和分隔符，返回分割后的table
function StrLink:split()
	local delimiter = ","
	local str = self.datastr
	if str==nil or str=='' or delimiter==nil then
		return nil
	end
	
    local result = {}
    for match in (str..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match)
    end
    if #result ~=0 then
		table.remove(result,#result)
    end
    return result
end
function StrLink:add(data)
	self.datastr = self.datastr..data..","
end
function StrLink:del(data)
	self.datastr = string.gsub(self.datastr,data.."," , "") 
end
function StrLink:finder(data)
	return string.find(self.datastr,data)
end
function StrLink:get()
	return self:split()
end
function StrLink:getTop()
	local ts = self:split()
	if ts ~= nil then
		return ts[1]
	end
	return 0
end
function StrLink:pop()
	local datas = self:split()
	if datas~= nil then
		print("del banlk"..datas[1])
		self:del(datas[1])
		return datas[1]
	end
end
function StrLink:cls()
	self.datastr = ""
end
function StrLink:getCount()
	local datas = self:split()
	if datas~= nil then
		return #datas
	end
	return 0
end
return StrLink