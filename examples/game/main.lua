local skynet = require "skynet"
local datacenter = require "skynet.datacenter"
local max_client = 100
local server_list = {}
local db
local pm
local tm
local gl
local dog
skynet.start(function()
	skynet.error("Server start")
	local console = skynet.newservice("console")
	skynet.newservice("debug_console",8000)
	-- gold var add
	db = skynet.newservice("testmysql")
	datacenter.set("db",db)
    pm = skynet.newservice("playermanager")
    datacenter.set("pm",pm)
    tm = skynet.newservice("tablemanager")
    datacenter.set("tm",tm)
    gl = skynet.newservice("goldmanager")
    datacenter.set("gl",gl)
	dog = skynet.newservice("watchdog")
	datacenter.set("dog",dog)
	skynet.call(dog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	skynet.error("Watchdog listen on", 8888)
--add user mode  start user mode
    server_list["login"] = skynet.newservice("login")
    server_list["grouplogic"] = skynet.newservice("grouplogic")
    server_list["commonlogic"] = skynet.newservice("commonlogic")
--set server_list to glob
    datacenter.set("server_list",server_list)
	skynet.exit()
end)
