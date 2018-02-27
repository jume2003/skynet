local MsgList = {}
--登录
MsgList.login = {
	login = {mode="login",cmd="login",info={code = 0}},
	register = {mode="login",cmd="register",info = {code = 0}}
}
--
MsgList.comman = {
	showbox = {mode="any",cmd="showbox",info={msg = ""}}
}
--大厅
MsgList.hall = {
	create_table = {mode="grouplogic",cmd="create_group"},
	exit_table = {mode="grouplogic",cmd="exit_group"},
	join_table = {mode="grouplogic",cmd="join_group",gid = 1},
}
--百人牛牛
MsgList.niuniu = {
	bet = {mode="grouplogic",cmd="game_msg",game_cmd = "bet",info ={place = 0,bet=0}},
}

return MsgList