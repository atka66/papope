extends Node2D

var spawners: Array[Node2D]
var determRandom: RandomNumberGenerator

var isNightclub: bool = false
var _stateAccum: float = 0.0
var _ghostAccum: float = 0.0

func _ready():
	determRandom = RandomNumberGenerator.new()
	# Synced seed: host rolls per round and broadcasts (online), fixed 123
	# offline. Tile variants + PREPARED items draw from this in fixed order.
	determRandom.set_seed(Global.matchSeed)
	
	$Dim.show()
	$HudCanvas/MapLabel.text = Global.selectedMap
	Global.MapControllerNode = self
	
	$AudioRoundStart.play()
	
	Global.MusicNode.play(Global.selectedMap)
	
	isNightclub = Global.selectedMap == 'nightclub'
	
	for child in get_parent().get_children():
		if child.is_in_group("pwrupSpawners"):
			spawners.append(child)

	Global.playersFrozen = true

	if Global.options['mode'][Global.optionsSelected['mode']] == 'cards':
		var perkOverlay = Res.PerkOverlayObject.instantiate()
		add_child(perkOverlay)
		if Net.isOnline:
			Net.flush_perk_sync()
		await perkOverlay.finished
	else:
		await get_tree().create_timer(1.5).timeout
	
	if !Net.isOnline || Net.isHost:
		pwrupSpawnLoop()
	initCountdown()
	await get_tree().create_timer(1.0).timeout
	for i in range(4):
		if Global.playersJoined[i]:
			spawnPlayer(i)
			await get_tree().create_timer(0.25).timeout

func _process(delta):
	# Host replicates player states to all clients ~20 times per second.
	if Net.isOnline and Net.isHost:
		_stateAccum += delta
		if _stateAccum >= Net.STATE_RATE:
			_stateAccum = 0.0
			Net.push_state(_collectStates())
		_ghostAccum += delta
		if _ghostAccum >= Net.GHOST_RATE:
			_ghostAccum = 0.0
			for ghost in get_tree().get_nodes_in_group("ghosts"):
				if is_instance_valid(ghost):
					Net.push_ghost((ghost as Node2D).global_position)
					break

func _collectStates() -> Array:
	return Global.getPlayerStates()

func _input(event):
	if event.is_action_pressed("quit"):
		if Net.isOnline:
			Net.leave()
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		else:
			Global.goToLobby()
	if Global.DEBUG && !Net.isOnline:
		if Input.is_action_just_pressed("test1"): 
			get_tree().change_scene_to_file("res://scenes/PostGame.tscn")

func pwrupSpawnLoop() -> void:
	await get_tree().create_timer(ProjectSettings.get("papope/pwrup_respawn_time")).timeout
	if Net.isOnline and Net.isHost and spawners.size() > 0:
		var spIdx := determRandom.randi_range(0, spawners.size() - 1)
		var typeIdx := determRandom.randi_range(0, Global.PwrupEnum.size() - 1)
		spawnNetPwrup(spIdx, typeIdx)
		Net.spawn_pwrup(spIdx, typeIdx)
	elif !Net.isOnline:
		var spawner = spawners.pick_random()
		if spawner != null:
			_spawnPwrupAt(spawner, Global.PwrupEnum.values().pick_random())
	pwrupSpawnLoop()

func spawnNetPwrup(spawnerIdx: int, typeIdx: int) -> void:
	if spawnerIdx < 0 or spawnerIdx >= spawners.size():
		return
	_spawnPwrupAt(spawners[spawnerIdx], typeIdx, spawnerIdx)

func despawnNetPwrup(spawnerIdx: int) -> void:
	if spawnerIdx < 0 or spawnerIdx >= spawners.size():
		return
	var pwrupGroupName = spawners[spawnerIdx].name + "pwrups"
	for spawnerPwrups in get_tree().get_nodes_in_group(pwrupGroupName):
		spawnerPwrups.despawn()

func _spawnPwrupAt(spawner: Node2D, type, spawnerIdx: int = -1) -> void:
	var pwrupGroupName = spawner.name + "pwrups"
	for spawnerPwrups in get_tree().get_nodes_in_group(pwrupGroupName):
		spawnerPwrups.despawn()
	var pwrup = Res.PwrupObject.instantiate()
	pwrup.add_to_group(pwrupGroupName)
	pwrup.type = type
	pwrup.netSpawner = spawnerIdx
	pwrup.position = spawner.position
	get_parent().add_child(pwrup)

func spawnPlayer(playerId : int) -> void:
	var player = Res.PlayerObject.instantiate()
	player.position = get_parent().get_node("PlayerSpawner" + str(playerId)).position
	player.playerId = playerId
	if Net.isOnline:
		player.isLocal = (playerId == Net.localSlot)
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
	# Online scoring is host-authoritative; clients render via showNetRoundEnd.
	if Net.isOnline and not Net.isHost:
		return
	$AudioRoundEnd.play()

	for player in get_tree().get_nodes_in_group('players'):
		if Global.playersJoined[player.playerId] && player.hp > 0 && player.hp <= Global.playersMaxHp[player.playerId] / 10:
			Global.registerAchievement(player.playerId, Global.AchiEnum.DAREDEVIL)

	Global.playersFrozen = true
	if aliveTeamId > -1: # team points are accounted
		for i in range(4):
			if Global.playersJoined[i] && Global.playersTeam[i] == aliveTeamId:
				Global.playersPoints[i] += 1

	_showRoundEndBanner(aliveTeamId)
	if Net.isOnline:
		Net.round_end(aliveTeamId, Global.playersPoints.duplicate())

func showNetRoundEnd(aliveTeamId: int) -> void:
	$AudioRoundEnd.play()
	Global.playersFrozen = true
	_showRoundEndBanner(aliveTeamId)

func _showRoundEndBanner(aliveTeamId: int) -> void:
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
	# Online ghosts are host-driven; clients spawn via Net.ghost_event.
	if Net.isOnline and not Net.isHost:
		return
	var nodeIdx := randi() % 2
	var colorIdx := randi() % 4
	if Net.isOnline:
		Net.ghost_event(nodeIdx, colorIdx)
	_ghostCountdown(nodeIdx, colorIdx)

func spawnNetGhost(nodeIdx: int, colorIdx: int = -1) -> void:
	_ghostCountdown(nodeIdx, colorIdx)

func _ghostCountdown(nodeIdx: int, colorIdx: int = -1) -> void:
	var spawnNode = get_parent().get_node('GhostPath/SpawnNode' + str(nodeIdx))
	var respawnTime = ProjectSettings.get("papope/ghost_respawn_time")
	for i in range(respawnTime):
		showCount(spawnNode.position, str(respawnTime - i))
		await get_tree().create_timer(1).timeout
	var ghost = Res.GhostObject.instantiate()
	ghost.netColorIdx = colorIdx
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
			body.fallDown(false)

func _on_conveyor_belt_body_entered(body):
	if body.is_in_group("players"):
		body.convey()

func _on_conveyor_belt_body_exited(body):
	if body.is_in_group("players"):
		body.unconvey()
		if !body.isFallingIntoWater:
			body.fallDown(true)

func _on_conveyor_belt_area_entered(area):
	if area.is_in_group("conveyables"):
		area.convey()

func _on_conveyor_belt_area_exited(area):
	if area.is_in_group("conveyables"):
		area.fallDown()
