extends Node2D

var screenShakePwr = 0

var cameraShakeOffset = Vector2.ZERO
var cameraPlayersOffset = Vector2.ZERO

func _ready():
	get_node('/root/Music').play(Global.selectedMap)

	Global.playersFrozen = true
	#scene _ready methods are unable to get parents or current scene
	add_child(Res.RoundStartBanner.instance())
	add_child(Res.Dim.instance())

	yield(get_tree().create_timer(1.5), "timeout")
	
	# cards mode card dealing
	if Global.options['mode'][Global.optionsSelected['mode']] == 'cards':
		var perkOverlay = Res.PerkOverlay.instance()
		add_child(perkOverlay)
		yield(perkOverlay, "finished")
	
	var a = _pwrupSpawnLoop()
	var b = initCountdown()
	yield(get_tree().create_timer(1), "timeout")
	for i in range(4):
		if Global.playersJoined[i]:
			var player = Res.Player.instance()
			player.position = get_parent().get_node("PlayerSpawner" + str(i)).position
			player.playerId = i
			get_parent().add_child(player)
			yield(get_tree().create_timer(0.25), "timeout")

func _pwrupSpawnLoop():
	yield(get_tree().create_timer(ProjectSettings.get("papope/pwrup_respawn_time")), "timeout")
	var spawner = getRandomSpawner()
	var pwrupGroupName = spawner.name
	for spawnersPwrup in get_tree().get_nodes_in_group(pwrupGroupName):
		spawnersPwrup.remove()
	var pwrup = Res.Pwrup.instance()
	pwrup.add_to_group(pwrupGroupName)
	pwrup.pwrupName = Res.PwrupSprites.keys()[randi() % Res.PwrupSprites.size()]
	pwrup.position = spawner.position
	get_parent().add_child(pwrup)
	var rerun = _pwrupSpawnLoop()

func getRandomSpawner():
	var spawners = []
	for child in get_parent().get_children():
		if child.is_in_group('spawners'):
			spawners.append(child)
	return spawners[randi() % len(spawners)]

func initCountdown():
	var countdown = Res.Countdown.instance()
	countdown.position = Vector2(340, 64)
	get_parent().add_child(countdown)

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
	get_parent().add_child(endBanner)

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

func _process(delta):
	calculatePlayersOffset()
	calculateShakeOffset()
	$Camera.position = cameraPlayersOffset + cameraShakeOffset

func calculatePlayersOffset():
	var center = Vector2(340, 192)
	var playerDiff = Vector2.ZERO
	var rawPlayers = get_tree().get_nodes_in_group('players')
	var players = []
	for player in rawPlayers:
		if player.alive:
			players.append(player)
	if !players.empty():
		for player in players:
			var playerPos = player.position - center
			playerDiff += playerPos.normalized() * pow(playerPos.length(), 0.7)
		playerDiff /= len(players)
	var offsetStep = (playerDiff - cameraPlayersOffset) / 4
	cameraPlayersOffset = cameraPlayersOffset + offsetStep

func calculateShakeOffset():
	if screenShakePwr > 0:
		cameraShakeOffset = Vector2((randi() % (screenShakePwr * 2)) - screenShakePwr, (randi() % (screenShakePwr * 2)) - screenShakePwr)
		screenShakePwr -= 1
	else:
		cameraShakeOffset = Vector2.ZERO

func playDestructibleDestroy():
	if !$AudioDestructibleDestroy.playing:
		$AudioDestructibleDestroy.stream = Res.AudioDestructibleDestroy[randi() % len(Res.AudioDestructibleDestroy)]
		$AudioDestructibleDestroy.play()

func playFallenPwrups():
	if !$AudioFallenPwrups.playing:
		$AudioFallenPwrups.play()

## TEST -- REMOVE
#func _input(event): if Input.is_action_just_pressed("test"): get_tree().change_scene("res://maps/PostGame.tscn")
