local M = {
    tbl = {},
    eye_tbl = {},
    feng_tbl = {},
    feng_eye_tbl = {}
}
local tb_path = "lualib/myfunlib/gui_table/"

function M:set_table(mj_table)
    self.tbl = mj_table.tbl
    self.eye_tbl = mj_table.eye_tbl
    self.feng_tbl = mj_table.feng_tbl
    self.feng_eye_tbl = mj_table.feng_eye_tbl
    return mj_table
end

function M:get_table()
    local mj_table = {
    tbl = self.tbl,
    eye_tbl = self.eye_tbl,
    feng_tbl = self.feng_tbl,
    feng_eye_tbl = self.feng_eye_tbl
    }
    return mj_table
end

function M:init()
    for i=0,8 do
        self.tbl[i] = {}
        self.eye_tbl[i] = {}
        self.feng_tbl[i] = {}
        self.feng_eye_tbl[i] = {}
    end
end

function M:add(key, gui_num, eye, chi)
    if not chi then
        if eye then
            self.feng_eye_tbl[gui_num][key] = true
        else
            self.feng_tbl[gui_num][key] = true
        end
    else
        if eye then
            self.eye_tbl[gui_num][key] = true
        else
            self.tbl[gui_num][key] = true
        end
    end

end

function M:check(key, gui_num, eye, chi)
    if not chi then
        if eye then
            return self.feng_eye_tbl[gui_num][key]
        else
            return self.feng_tbl[gui_num][key]
        end
    else
        if eye then
            return self.eye_tbl[gui_num][key]
        else
            return self.tbl[gui_num][key]
        end
    end
end

function M:load()
    for i=0,8 do
        self:_load(string.format(tb_path.."tbl/table_%d.tbl",i), self.tbl[i])
        self:_load(string.format(tb_path.."tbl/eye_table_%d.tbl",i), self.eye_tbl[i])
        self:_load(string.format(tb_path.."tbl/feng_table_%d.tbl",i), self.feng_tbl[i])
        self:_load(string.format(tb_path.."tbl/feng_eye_table_%d.tbl",i), self.feng_eye_tbl[i])
    end
end

function M:dump_table()
    for i=0,8 do
        self:_dump(string.format(tb_path.."tbl/table_%d.tbl", i), self.tbl[i])
        self:_dump(string.format(tb_path.."tbl/eye_table_%d.tbl", i), self.eye_tbl[i])
    end
end

function M:dump_feng_table()
    for i=0,8 do
        self:_dump(string.format(tb_path.."tbl/feng_table_%d.tbl", i), self.feng_tbl[i])
        self:_dump(string.format(tb_path.."tbl/feng_eye_table_%d.tbl", i), self.feng_eye_tbl[i])
    end
end

function M:_load(file, tbl)
    local num = 0
    local f = io.open(file, "r")
    while true do
        local line = f:read()
        if not line then
            break
        end
        num = num + 1
        tbl[tonumber(line)] = true
    end
    f:close()
    --print(file, num)
end

function M:_dump(file, tbl)
    local f = io.open(file, "w+")
    for k,_ in pairs(tbl) do
        f:write(k.."\n")
    end
    f:close()
end

return M
