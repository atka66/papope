extends Node2D

func _ready():
	get_tree().refuse_new_network_connections = false
	get_tree().connect("network_peer_connected", self, "net_connect")
	get_tree().connect("network_peer_disconnected", self, "net_disconnect")
	get_tree().connect("server_disconnected", self, "cli_disconnect")
	if get_tree().is_network_server():
		Global.playersNetInfo[0] = "server"
	
	get_node('/root/Music').play('menu')

func net_connect(id):
	rpc_id(id, "registerPlayer", "client")
	Global.growl("player joined")

func net_disconnect(id):
	Global.growl("player left")
	
func cli_disconnect():
	Global.growl("disconnected from server")
	exitToMainmenu()

remote func registerPlayer(name):
	Global.playersNetInfo[get_tree().get_rpc_sender_id()] = name


func _input(event): 
	if Input.is_action_just_pressed("quit"):
		exitToMainmenu()
	if Global.DEBUG: 
		if Input.is_action_just_pressed("test1"): 
			for i in range(4):
				if !Global.playersConnected[i]:
					Global.playersConnected[i] = true
					break
				if !Global.playersJoined[i]:
					Global.playersJoined[i] = true
					Global.joinPlayer(i, false)
					break
		if Input.is_action_just_pressed("test2"): 
			for i in range(4):
				if Global.playersConnected[i]:
					if Global.playersJoined[i]:
						Global.playersJoined[i] = false
						Global.leavePlayer(i)
						break
		if Input.is_action_just_pressed("test3"):
			Global.goToMap()

func exitToMainmenu():
	get_tree().network_peer = null
	get_tree().change_scene(Res.MainmenuPath)
