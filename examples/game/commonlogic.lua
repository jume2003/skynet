local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local mysocket = require "mysocket"
local pm = require "playerctrl"
local tm = require "tablectrl"
local CMD = {}
local db
local dog
local last_asktime = {}
local heartbet_list = {}
--
function CMD.rank(msg)
    print(os.time())
    if last_asktime[msg.fd] and os.time()-last_asktime[msg.fd] < 3 then 
        print("so fast ask "..os.time()-last_asktime[msg.fd])
        return
    end
    local sql = "SELECT * FROM user ORDER BY coin DESC"
    local ret = skynet.call(db, "lua", "query", sql,true)
    skynet.call(db, "lua", "dump",ret)
    last_asktime[msg.fd] = os.time()
    local ret_rank = {cmd = "rank",mode= "hall",info={trank={},crank={}}}
    for i=1,#ret>20 and 20 or #ret,1 do
        ret[i].loginpass = nil
        ret[i].create_time = nil
        ret[i].bankpass = nil
        ret_rank.info.trank[i] = {}
        ret_rank.info.crank[i] = {}
        ret_rank.info.trank[i] = ret[i]
        ret_rank.info.crank[i] = ret[i]
    end
    mysocket.write(msg.fd, ret_rank)
end
--gamelist
function CMD.gamelist(msg)
         local info = {game_id={},game_name={}}
         for i=1,10,1 do  
          info.game_id[i] = i
          info.game_name[i] =  math.random(10)
         end  

         local ret_code = {}
         ret_code.cmd = "gamelist"
         ret_code.info = info
         mysocket.write(msg.fd, ret_code)
end
--mil
function CMD.mil(msg)
    print(os.time())
    if last_asktime[msg.fd] and os.time()-last_asktime[msg.fd] < 3 then 
    print("so fast ask "..os.time()-last_asktime[msg.fd])
    return
    end
    last_asktime[msg.fd] = os.time()
    local ret_mil = {cmd = "mil",mode= "hall",info={emil={}}}
    for i=1,20,1 do
        ret_mil.info.emil[i] = {}
        ret_mil.info.emil[i].title = "850 充值中心:weixin555888"
        ret_mil.info.emil[i].eid = i
        ret_mil.info.emil[i].msg = "充值中心充值中心充值中心充值中心"
        ret_mil.info.emil[i].sender = "system"
        ret_mil.info.emil[i].data = os.date()
        ret_mil.info.emil[i].isopen = 1
    end
    mysocket.write(msg.fd, ret_mil)
end
--请求用户信息
function CMD.userinfo(msg)
    local user = pm.getbyfd(msg.fd)
    if user then
        local ret_userinfo = {cmd = "userinfo",mode= "any",info={}}
        ret_userinfo.info = user
        mysocket.write(msg.fd, ret_userinfo)
    end
end
--heartbet
function CMD.heartbet(msg)
    local ret_heartbet = {cmd = "heartbet",mode= "any",info={sevtime = os.time()}}
     mysocket.write(msg.fd, ret_heartbet)
     heartbet_list[msg.fd] = os.time()
     --print("heartbet")
end
--当心跳包超过3秒没收到就是掉线了（向dog发断开）
function heartbet_timeout()
    for k,v in pairs(heartbet_list) do
        if os.time() - v > 20 then
            skynet.call(dog, "lua", "close",k)
            heartbet_list[k] = nil
            print("heartbet_timeout fd"..k)
        end
    end
end


skynet.start(function()
	db = datacenter.get("db")
    dog = datacenter.get("dog")
    pm.init(datacenter.get("pm"))
    tm.init(datacenter.get("tm"))
    skynet.fork(function()
        while true do
            heartbet_timeout()
            skynet.sleep(100)
        end
    end)
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		local f = CMD[cmd]
		if f then
		   skynet.ret(skynet.pack(f(subcmd, ...)))
	    end
	end)
end)
