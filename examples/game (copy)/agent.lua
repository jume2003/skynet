local skynet = require "skynet"
local netpack = require "skynet.netpack"
local socket = require "skynet.socket"
local datacenter = require "skynet.datacenter"
local json = require "json"
local pm = require "playerctrl"
local tm = require "tablectrl"
local db
local WATCHDOG
local host
local send_request

local CMD = {}
local client_fd

local server_list = {}

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)

		return "socketdata",msg,sz
	end,
	dispatch = function (_, _, type, ...)
	    if type == "socketdata" then
           local args = {...}
	       CMD.dispatchdata(args[1],args[2])
	    end
	end
}

function CMD.dispatchdata(msg,sz)
	-- msg to json string
    local str = skynet.tostring(msg,sz)
    --josn to table 
    local ret = json.decode(str)
    ret.fd = client_fd
    if ret.cmd and ret.cmd ~="heartbet" then
    	print("rec:")
    	skynet.call(db, "lua", "dump",ret)
	end
    local mode = server_list[ret.mode]
    local user = pm.getbyfd(client_fd)
    if mode then
     skynet.call(mode, "lua",ret.cmd ,ret)
    else
      print("error no mode "..ret.mode)
    end
    if user == nil and ret.cmd and ret.cmd ~="heartbet" then
    	print("agent not login")
    end

     --skynet.error("dispatchdata "..str.." "..sz)
	 --local sql = string.format("insert into cats (name) values (\'%s\')", os.time())
	 --local ret = skynet.call(db, "lua", "query", sql,true)
     --local ret = skynet.call(db, "lua", "query", "SELECT * FROM skynet.cats where name = \'Bob\'")
     --skynet.call(db, "lua", "dump",ret)
     --print(ret[1].name)
end

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
	server_list = datacenter.get("server_list")
	db = datacenter.get("db")
end

function CMD.disconnect()
	local mode = server_list["grouplogic"]
	skynet.call(mode, "lua","disconnect",client_fd)
    --print("disconnect a")
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	pm.init(datacenter.get("pm"))
    tm.init(datacenter.get("tm"))
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
