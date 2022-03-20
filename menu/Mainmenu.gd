extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	get_tree().connect("connected_to_server", self, "_connectOk")
	get_tree().connect("connection_failed", self, "_connectFail")
	get_node('/root/Music').play('menu')
	updateAnim()

func _input(event):
	if $OnlineDialog.visible:
		if Input.is_action_just_pressed("quit"):
			$OnlineDialog.hide()
			$GameTypeHolder.show()
	elif $HostDialog.visible:
		if Input.is_action_just_pressed("quit"):
			$OnlineDialog.popup()
			$HostDialog.hide()
	elif $JoinDialog.visible:
		if Input.is_action_just_pressed("quit"):
			$OnlineDialog.popup()
			$JoinDialog.hide()
	elif $ConnectDialog.visible:
		if Input.is_action_just_pressed("quit"):
			failConnection()
	else:
		if Input.is_action_just_pressed("quit"):
			get_tree().quit()
		if (Input.is_action_just_pressed("pl_nav_down") ||
			Input.is_action_just_pressed("pl_nav_up")):
			Global.onlinemode = !Global.onlinemode
			updateAnim()
		if Input.is_action_just_released("ui_accept"):
			if Global.onlinemode:
				$OnlineDialog.popup()
				$GameTypeHolder.hide()
			else:
				get_tree().change_scene(Res.LobbyPath)

func updateAnim():
	if Global.onlinemode:
		$GameTypeHolder/Anim.play("wobble_online")
		$GameTypeHolder/LocalHolder.scale = Vector2.ONE
		$GameTypeHolder/LocalHolder.rotation_degrees = 0
	if !Global.onlinemode:
		$GameTypeHolder/Anim.play("wobble_local")
		$GameTypeHolder/OnlineHolder.scale = Vector2.ONE
		$GameTypeHolder/OnlineHolder.rotation_degrees = 0

func _on_HostButton_pressed():
	$HostDialog.popup()
	$OnlineDialog.hide()

func _on_JoinButton_pressed():
	$JoinDialog.popup()
	$OnlineDialog.hide()

func _on_RefreshButton_pressed():
	var item = Res.ServerListItem.instance()
	$JoinDialog/Content/ServerList.add_child(item)

func _on_IpEdit_text_entered(new_text):
	$ConnectDialog.popup()
	$JoinDialog.hide()
	# joining to a given address
	var peer = NetworkedMultiplayerENet.new()
	if peer.create_client(new_text, Global.NET_PORT) > 0:
		failConnection()
	get_tree().network_peer = peer

func _on_ServernameEdit_text_entered(new_text):
	# hosting a game
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(Global.NET_PORT, 4)
	get_tree().network_peer = peer
	get_tree().change_scene(Res.NetLobbyPath)

func _connectOk():
	get_tree().change_scene(Res.NetLobbyPath)

func _connectFail():
	failConnection()

func failConnection():
	get_tree().network_peer = null
	Global.growl('could not connect to server')
	$AudioError.play()
	$JoinDialog.popup()
	$ConnectDialog.hide()
