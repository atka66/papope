extends Node2D

func _ready():
	Global.playersFrozen = true
	var mapLabel = Res.CustomLabel.instance()
	mapLabel.position.x = 64
	mapLabel.position.y = 288
	mapLabel.text = Global.selectedMap
	mapLabel.fontSize = 6
	mapLabel.outline = true
	mapLabel.aliveTime = 2
	mapLabel.alignment = Label.ALIGN_LEFT
	mapLabel.audio = Res.AudioRoundStart
	#scene _ready methods are unable to get parents or current scene
	get_tree().get_root().add_child(mapLabel)
	get_tree().get_root().add_child(Res.Dim.instance())
	var a = _pwrupSpawnLoop()
	var b = initCountdown()
	yield(get_tree().create_timer(2), "timeout")
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
	yield(get_tree().create_timer(1), "timeout")
	var countdown = Res.Countdown.instance()
	countdown.position = Vector2(340, 64)
	get_parent().add_child(countdown)

func endRound(aliveTeamId):
	# check daredevil achievement
	for player in get_tree().get_nodes_in_group('players'):
		if Global.playersJoined[player.playerId] && player.alive && player.hp <= Global.options['hp'][Global.optionsSelected['hp']] / 10:
			Global.registerAchievement(player.playerId, Global.Achi.DAREDEVIL)
	
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
	winLabel.aliveTime = 3
	winLabel.alignment = Label.ALIGN_CENTER
	get_parent().add_child(winLabel)
	yield(get_tree().create_timer(3), "timeout")
	Global.goToMap()
