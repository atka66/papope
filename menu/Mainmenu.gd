extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node('/root/Music').play('menu')
	updateAnim()

func _input(event):
	if $OnlineDialog.visible:
		if Input.is_action_just_pressed("quit"):
			$OnlineDialog.hide()
			$GameTypeHolder.show()
	elif $JoinDialog.visible:
		if Input.is_action_just_pressed("quit"):
			$OnlineDialog.popup()
			$JoinDialog.hide()
	else:
		if Input.is_action_just_pressed("quit"):
			get_tree().quit()
		if (Input.is_action_just_pressed("pl_nav_down") ||
			Input.is_action_just_pressed("pl_nav_up")):
			Global.onlinemode = !Global.onlinemode
			updateAnim()
		if Input.is_action_just_pressed("ui_accept"):
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
	pass

func _on_JoinButton_pressed():
	$JoinDialog.popup()
	$OnlineDialog.hide()

func _on_RefreshButton_pressed():
	var item = Res.ServerListItem.instance()
	$JoinDialog/Content/ServerList.add_child(item)
