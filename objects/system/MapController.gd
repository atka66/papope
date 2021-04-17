extends Node2D

var screenShakePwr = 0

func _ready():
	Global.playersFrozen = true
	var mapLabel = Res.CustomLabel.instance()
	mapLabel.position.x = 64
	mapLabel.position.y = 288
	mapLabel.text = Global.selectedMap
	mapLabel.fontSize = 6
	mapLabel.outline = true
	mapLabel.aliveTime = 1
	mapLabel.alignment = Label.ALIGN_LEFT
	mapLabel.audio = Res.AudioRoundStart
	#scene _ready methods are unable to get parents or current scene
	add_child(mapLabel)
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
	
	var toastText = "draw"
	if aliveTeamId != -2:
		toastText = Global.TEAM_COLOR_STRINGS[aliveTeamId] + " wins"
	var winLabel = Res.CustomLabel.instance()
	winLabel.position = Vector2(340, 64)
	winLabel.text = toastText
	winLabel.fontSize = 3
	winLabel.outline = true
	winLabel.aliveTime = 4
	winLabel.alignment = Label.ALIGN_CENTER
	winLabel.audio = Res.AudioRoundEnd
	get_parent().add_child(winLabel)
	yield(get_tree().create_timer(4), "timeout")
	Global.goToMap()

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
	if screenShakePwr > 0:
		$Camera.position = Vector2((randi() % (screenShakePwr * 2)) - screenShakePwr, (randi() % (screenShakePwr * 2)) - screenShakePwr)
		screenShakePwr -= 1
	else:
		$Camera.position = Vector2.ZERO
