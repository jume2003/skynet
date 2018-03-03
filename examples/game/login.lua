local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local json = require "json"
local pm = require "playerctrl"
local tm = require "tablectrl"
local mysocket = require "mysocket"
local webclient_lib = require 'webclient.core'
local webclient = webclient_lib.create()
local MsgList = require 'MsgList'
local login_msg = MsgList.login
local comman_msg = MsgList.comman
local CMD = {}
local db
local dog
local msg_login = {mode="login",cmd="login",user="1",password="1"}
local msg_register = {mode="login",cmd="register",user="123",loginpass="123456",nick_name="333",sex=1,touxian = 1}

local function https_get(url)
  local requests = {}
  local req, key = webclient:request(url)
  requests[key] = req
  while next(requests) do
    local finish_key, result = webclient:query()
    if finish_key then
      local req = requests[finish_key]
      assert(req)
      requests[finish_key] = nil
    
      assert(result == 0)
    
      local content, errmsg = webclient:get_respond(req)
      webclient:remove_request(req)
      return content,errmsg
    end
  end
end


function CMD.wxlogin(msg)
  skynet.fork(function()
      --客户端发code 过来
        local appid = "wxfc38c3d10dfb4319"
        local secret = "a513bf76a54016140c34780cd688599a"
        local code = msg.code
        local token_url = string.format("https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code",appid,secret,code) 
      --得到token
        local content, errmsg = https_get(token_url)
        local token_table = json.decode(content)
        if token_table.errcode then
          return
        end
        --print(token_table.access_token)
        --print(content)
        local token = token_table.access_token
        local openid = token_table.openid
        local info_url = string.format("https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s",token,openid) 
        content, errmsg = https_get(info_url)
        content = string.gsub(content, "\\", "") 
        local info_table = json.decode(content)
        if info_table.errcode then
          return
        end
      --得到用户信息
        print("tostring(info_table.unionid)"..tostring(info_table.unionid))
        local sql = string.format("SELECT * FROM user where user = (\'%s\')", tostring(info_table.unionid))
        
        local ret = skynet.call(db, "lua", "query", sql,true)
        if ret and #ret>0 then
            --已存在就登录
            msg_login.user = tostring(info_table.unionid)
            msg_login.password = tostring(info_table.unionid)
            msg_login.fd = msg.fd
            CMD.login(msg_login)
        else
            --不存在就注册
            msg_register.user = tostring(info_table.unionid)
            msg_register.loginpass = tostring(info_table.unionid)
            msg_register.nick_name = info_table.nickname
            msg_register.sex= info_table.sex
            msg_register.touxian = info_table.headimgurl
            msg_register.fd = msg.fd
            CMD.register(msg_register)
            --登录
            msg_login.user = tostring(info_table.unionid)
            msg_login.password = tostring(info_table.unionid)
            msg_login.fd = msg.fd
            CMD.login(msg_login)
        end

  end)

end

function CMD.login(msg)
    local sql = string.format("SELECT * FROM user where user = (\'%s\')", msg.user)
    local ret = skynet.call(db, "lua", "query", sql,true)
    local error_code = 0

    if pm.getbyfd(msg.fd) then 
       error_code = 5
       print("logined")
    elseif ret and #ret>0 then
       local user = pm.get(ret[1].uid)
       if user and user.fd > 0 then
         --重登把旧的那个人逼下线
          skynet.call(dog, "lua", "close",user.fd) 
          error_code = 4
       elseif ret[1].loginpass == msg.password then
       	  error_code = 1
       else
       	  error_code = 2
       end
    else
      error_code = 3
    end

    local ret_msg = ""
    if error_code == 1 then
      pm.del(ret[1].uid)
      pm.add(ret[1],msg.fd)
      ret_msg = "登录成功"
    elseif error_code == 2 then
      ret_msg = "密码错误"
    elseif error_code == 3 then
      ret_msg =  "用户不存在"
    elseif error_code == 4 then
      ret_msg =  "用户重登"
    elseif error_code == 5 then
      ret_msg =  "断线重登"
    end
    login_msg.login.info.code = ret_msg
    comman_msg.showbox.info.msg = ret_msg
    mysocket.write(msg.fd, login_msg.login)
    
    if error_code ~= 1 then
      mysocket.write(msg.fd, comman_msg.showbox)
    end
end

function CMD.exitlogin(msg)
   local user = pm.getbyfd(msg.fd)
    if user then
    user.fd = -user.uid
    pm.set(user)
    print("exitlogin uid"..user.uid)
    end
end

function CMD.register(msg)
    local sql = string.format("SELECT * FROM user where user = (\'%s\')", msg.user)
    local ret = skynet.call(db, "lua", "query", sql,true)
    local error_code = 0
    local ret_msg = ""

    if ret and #ret==0 and #msg.user>0 and #msg.loginpass>0 then
       sql = string.format("insert into user (user,loginpass,nick_name,email,sex,create_time,coin,card,touxian) values (\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',\'%s\',\'%s\')",msg.user,msg.loginpass,msg.nick_name,msg.email,msg.sex,os.time(),1000,4,msg.touxian)
       skynet.call(db, "lua", "query", sql,true)
       print("create user "..msg.user)
       error_code = 1
    else
       error_code = 2
    end
 
    if error_code == 1 then
      ret_msg = "注册成功"
    elseif error_code == 2 then
      ret_msg = "用户已注册"
    end
    login_msg.register.info.code = ret_msg
    comman_msg.showbox.info.msg = ret_msg
    mysocket.write(msg.fd, login_msg.register)
    mysocket.write(msg.fd, comman_msg.showbox)
end

skynet.start(function()
	db = datacenter.get("db")
  dog = datacenter.get("dog")
  pm.init(datacenter.get("pm"))
  tm.init(datacenter.get("tm"))
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = CMD[cmd]
		if f then
		   skynet.ret(skynet.pack(f(subcmd, ...)))
	    end
	end)
end)
