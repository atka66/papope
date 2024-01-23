extends Node2D

var spawners: Array[Node2D]
var determRandom: RandomNumberGenerator

func _ready():
	determRandom = RandomNumberGenerator.new()
	determRandom.set_seed(123)
	
	$Dim.show()
	$HudCanvas/MapLabel.text = Global.selectedMap
	Global.MapControllerNode = self
	
	$AudioRoundStart.play()
	
	Global.MusicNode.play(Global.selectedMap)
	
	for child in get_parent().get_children():
		if child.is_in_group("pwrupSpawners"):
			spawners.append(child)

	Global.playersFrozen = true

	if Global.options['mode'][Global.optionsSelected['mode']] == 'cards':
		var perkOverlay = Res.PerkOverlayObject.instantiate()
		add_child(perkOverlay)
		await perkOverlay.finished
	else:
		await get_tree().create_timer(1.5).timeout
	
	pwrupSpawnLoop()
	initCountdown()
	await get_tree().create_timer(1.0).timeout
	for i in range(4):
		if Global.playersJoined[i]:
			spawnPlayer(i)
			await get_tree().create_timer(0.25).timeout

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	if Global.DEBUG:
		if Input.is_action_just_pressed("test1"): 
			get_tree().change_scene_to_file("res://scenes/PostGame.tscn")

func pwrupSpawnLoop() -> void:
	await get_tree().create_timer(ProjectSettings.get("papope/pwrup_respawn_time")).timeout
	var spawner = spawners.pick_random()
	if spawner != null:
		var pwrupGroupName = spawner.name + "pwrups"
		for spawnerPwrups in get_tree().get_nodes_in_group(pwrupGroupName):
			spawnerPwrups.despawn()
		var pwrup = Res.PwrupObject.instantiate()
		pwrup.add_to_group(pwrupGroupName)
		pwrup.type = Global.PwrupEnum.values().pick_random()
		pwrup.position = spawner.position
		get_parent().add_child(pwrup)
	pwrupSpawnLoop()

func spawnPlayer(playerId : int) -> void:
	var player = Res.PlayerObject.instantiate()
	player.position = get_parent().get_node("PlayerSpawner" + str(playerId)).position
	player.playerId = playerId
	get_parent().add_child(player)
	player.hud = spawnPlayerHud(player)

func spawnPlayerHud(player : RigidBody2D) -> Object:
	var hud = Res.HudObject.instantiate()
	if player.playerId == 0: hud.position = Vector2(0, 8)
	if player.playerId == 1: hud.position = Vector2(1136, 8)
	if player.playerId == 2: hud.position = Vector2(0, 648)
	if player.playerId == 3: hud.position = Vector2(1136, 648)
	hud.name = 'Hud' + str(player.playerId)
	hud.player = player
	hud.fromRight = player.playerId % 2 == 1
	hud.fromTop = player.playerId < 2
	$HudCanvas.add_child(hud)
	return hud

func initCountdown() -> void:
	var countdown = Res.CountdownObject.instantiate()
	countdown.position = Vector2(680, 128)
	$HudCanvas.add_child(countdown)

func endRound(aliveTeamId: int) -> void:
	$AudioRoundEnd.play()
	
	for player in get_tree().get_nodes_in_group('players'):
		if Global.playersJoined[player.playerId] && player.hp > 0 && player.hp <= Global.playersMaxHp[player.playerId] / 10:
			Global.registerAchievement(player.playerId, Global.AchiEnum.DAREDEVIL)

	Global.playersFrozen = true
	if aliveTeamId > -1: # team points are accounted
		for i in range(4):
			if Global.playersJoined[i] && Global.playersTeam[i] == aliveTeamId:
				Global.playersPoints[i] += 1
	
	var endBanner = Res.RoundEndBannerObject.instantiate()
	endBanner.aliveTeamId = aliveTeamId
	$HudCanvas.add_child(endBanner)

func playGoSound() -> void:
	$AudioRoundGo.play()

func showCount(position: Vector2, cnt: String) -> void:
	var label = Res.CustomLabelObject.instantiate()
	label.position = position
	label.text = cnt
	label.fontSize = 4
	label.alignment = Control.LayoutPreset.PRESET_CENTER
	label.animation = 'float_in'
	label.aliveTime = 1
	add_child(label)

func initGhostSpawn() -> void:
	var spawnNode = get_parent().get_node('GhostPath/SpawnNode' + str(randi() % 2))
	var respawnTime = ProjectSettings.get("papope/ghost_respawn_time")
	for i in range(respawnTime):
		showCount(spawnNode.position, str(respawnTime - i))
		await get_tree().create_timer(1).timeout
	var ghost = Res.GhostObject.instantiate()
	ghost.destNode = spawnNode
	get_parent().add_child(ghost)

func _on_space_trigger_body_entered(body):
	if body.is_in_group("players"):
		body.inSpace = true

func _on_space_trigger_body_exited(body):
	if body.is_in_group("players"):
		body.inSpace = false

func _on_lava_body_entered(body):
	if body.is_in_group("players"):
		body.enteredLava()

func _on_lava_body_exited(body):
	if body.is_in_group("players"):
		body.exitedLava()

func _on_fall_trigger_body_entered(body):
	if body.is_in_group("players"):
		if !body.isFallingIntoWater:
			body.fallIntoWater()


func _on_conveyor_belt_body_entered(body):
	if body.is_in_group("players"):
		#body.convey() TODO
		pass


func _on_conveyor_belt_body_exited(body):
	if body.is_in_group("players"):
		if !body.isFallingIntoWater:
			#body.fallIntoWater() TODO
			pass
