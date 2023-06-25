extends Node2D

func _ready():
	get_node("/root/Music").play(Global.selectedMap)

	Global.playersFrozen = true
	
	var mapLabel = Res.CustomLabelObject.instantiate()
	mapLabel.fontSize = 6
	$HudCanvas.add_child(mapLabel)
	
	# todo cards
	await get_tree().create_timer(1.5).timeout
	
	# todo pwrup spawn
	
	
	initCountdown()
	await get_tree().create_timer(1.0).timeout
	for i in range(4):
		if Global.playersJoined[i]:
			spawnPlayer(i)
			await get_tree().create_timer(0.25).timeout

func spawnPlayer(playerId : int) -> void:
	var player = Res.PlayerObject.instantiate()
	player.position = get_parent().get_node("PlayerSpawner" + str(playerId)).position
	player.playerId = playerId
	get_parent().add_child(player)
	# TODO spawnPlayerHud(player)

func spawnPlayerHud(player : PackedScene) -> void:
	var hud = Res.HudObject.instantiate()
	if player.playerId == 0: hud.position = Vector2(-120, 4)
	if player.playerId == 1: hud.position = Vector2(688, 4)
	if player.playerId == 2: hud.position = Vector2(-120, 324)
	if player.playerId == 3: hud.position = Vector2(688, 324)
	hud.name = 'Hud' + str(player.playerId)
	hud.player = player
	hud.fromRight = (player.playerId % 2 == 1)
	$HudCanvas.add_child(hud)

func initCountdown() -> void:
	var countdown = Res.CountdownObject.instantiate()
	countdown.position = Vector2(340, 64)
	$HudCanvas.add_child(countdown)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
