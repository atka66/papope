extends Node2D

func _ready():
	get_node('/root/Music').play(Global.selectedMap)

	Global.playersFrozen = true
	#scene _ready methods are unable to get parents or current scene
	$HudCanvas.add_child(Res.RoundStartBanner.instance())
	$HudCanvas.add_child(Res.Dim.instance())

	# cards mode card dealing
	if Global.options['mode'][Global.optionsSelected['mode']] == 'cards':
		var perkOverlay = Res.PerkOverlay.instance()
		add_child(perkOverlay)
		yield(perkOverlay, "finished")
	else:
		yield(get_tree().create_timer(1.5), "timeout")

	var a = _pwrupSpawnLoop()
	var b = initCountdown()
	yield(get_tree().create_timer(1), "timeout")
	for i in range(4):
		if Global.playersJoined[i]:
			spawnPlayer(i)
			yield(get_tree().create_timer(0.25), "timeout")

func _pwrupSpawnLoop():
	yield(get_tree().create_timer(ProjectSettings.get("papope/pwrup_respawn_time")), "timeout")
	var spawner = getRandomSpawner()
	var pwrupGroupName = spawner.name
	for spawnersPwrup in get_tree().get_nodes_in_group(pwrupGroupName):
		spawnersPwrup.remove()
	var pwrup = Res.Pwrup.instance()
	pwrup.add_to_group(pwrupGroupName)
	pwrup.pwrupName = Global.getRandomPwrupName()
	pwrup.position = spawner.position
	get_parent().add_child(pwrup)
	var rerun = _pwrupSpawnLoop()

func spawnPlayer(playerId):
	var player = Res.Player.instance()
	player.position = get_parent().get_node("PlayerSpawner" + str(playerId)).position
	player.playerId = playerId
	get_parent().add_child(player)
	spawnPlayerHud(player)

func spawnPlayerHud(player):
	var hud = Res.Hud.instance()
	var position = Vector2.ZERO
	if player.playerId == 0: position = Vector2(-120, 4)
	if player.playerId == 1: position = Vector2(688, 4)
	if player.playerId == 2: position = Vector2(-120, 324)
	if player.playerId == 3: position = Vector2(688, 324)
	hud.name = 'Hud' + str(player.playerId)
	hud.position = position
	hud.player = player
	hud.fromRight = (player.playerId % 2 == 1)
	$HudCanvas.add_child(hud)

func getRandomSpawner():
	var spawners = []
	for child in get_parent().get_children():
		if child.is_in_group('spawners'):
			spawners.append(child)
	return spawners[randi() % len(spawners)]

func initCountdown():
	var countdown = Res.Countdown.instance()
	countdown.position = Vector2(340, 64)
	$HudCanvas.add_child(countdown)

func endRound(aliveTeamId):
	# check daredevil achievement
	for player in get_tree().get_nodes_in_group('players'):
		if Global.playersJoined[player.playerId] && player.hp > 0 && player.hp <= Global.playersMaxHp[player.playerId] / 10:
			Global.registerAchievement(player.playerId, Global.AchiEnum.DAREDEVIL)
	
	Global.playersFrozen = true
	if aliveTeamId > -1: # team points are accounted
		for i in range(4):
			if Global.playersJoined[i] && Global.playersTeam[i] == aliveTeamId:
				Global.playersPoints[i] += 1
	
	var endBanner = Res.RoundEndBanner.instance()
	endBanner.aliveTeamId = aliveTeamId
	$HudCanvas.add_child(endBanner)

func showCount(pos, cnt):
	var label = Res.CustomLabel.instance()
	label.position = pos - Vector2(0, 6)
	label.text = cnt
	label.fontSize = 3
	label.aliveTime = 1
	label.alignment = Label.ALIGN_CENTER
	label.color = Color.blue
	get_parent().add_child(label)

func initGhostSpawn():
	var spawnNode = get_parent().get_node('GhostPathNode' + str(randi() % 2))
	var cd = ProjectSettings.get("papope/ghost_respawn_time")
	for i in range(cd):
		showCount(spawnNode.position, str(cd - i))
		yield(get_tree().create_timer(1), "timeout")
	var ghost = Res.Ghost.instance()
	ghost.destNode = spawnNode
	get_parent().add_child(ghost)

func playDestructibleDestroy():
	if !$AudioDestructibleDestroy.playing:
		$AudioDestructibleDestroy.stream = Res.AudioDestructibleDestroy[randi() % len(Res.AudioDestructibleDestroy)]
		$AudioDestructibleDestroy.play()

func playFallenPwrups():
	if !$AudioFallenPwrups.playing:
		$AudioFallenPwrups.play()

func _input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().change_scene(Res.LobbyPath)
	if Global.DEBUG:
		if Input.is_action_just_pressed("test1"): 
			get_tree().change_scene(Res.PostGamePath)
