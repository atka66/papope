extends Node2D

func _ready():
	Global.playersFrozen = true
	var mapLabel = Global.CustomLabel.instance()
	mapLabel.position.x = 64
	mapLabel.position.y = 288
	mapLabel.text = Global.selectedMap
	mapLabel.fontSize = 6
	mapLabel.outline = true
	mapLabel.aliveTime = 2
	mapLabel.alignment = Label.ALIGN_LEFT
	add_child(mapLabel)
	var a = initSpawnPwrup()
	var b = initCountdown()
	yield(get_tree().create_timer(2), "timeout")
	for i in range(4):
		if Global.playersJoined[i]:
			var player = Global.Player.instance()
			player.position = get_parent().get_node("PlayerSpawner" + str(i)).position
			player.playerId = i
			add_child(player)
			yield(get_tree().create_timer(0.25), "timeout")

func initSpawnPwrup():
	yield(get_tree().create_timer(2), "timeout") #TODO set to 10
	spawnRandomPwrup()

func spawnRandomPwrup():
	var spawner = getRandomSpawner()
	var pwrupGroupName = spawner.name
	for spawnersPwrup in get_tree().get_nodes_in_group(pwrupGroupName):
		spawnersPwrup.remove()
	var pwrup = Global.Pwrup.instance()
	pwrup.add_to_group(pwrupGroupName)
	pwrup.pwrupName = Global.PwrupSprites.keys()[randi() % Global.PwrupSprites.size()]
	pwrup.position = spawner.position
	get_parent().add_child(pwrup)
	yield(get_tree().create_timer(3), "timeout") #TODO set to 6
	var rerun = spawnRandomPwrup()

func getRandomSpawner():
	var spawners = []
	for child in get_parent().get_children():
		if child.is_in_group('spawners'):
			spawners.append(child)
	return spawners[randi() % len(spawners)]

func initCountdown():
	yield(get_tree().create_timer(1), "timeout")
	var countdown = Global.Countdown.instance()
	countdown.position = Vector2(340, 64)
	add_child(countdown)

func endRound(aliveTeamId):
	Global.playersFrozen = true
	if aliveTeamId > -1: # team points are accounted
		for i in Global.playersTeam:
			if Global.playersJoined[i] && Global.playersTeam[i] == aliveTeamId:
				Global.playersPoints[i] += 1
	
	var toastText = "draw"
	if aliveTeamId != -2:
		toastText = Global.TEAM_COLOR_STRINGS[aliveTeamId] + " WINS"
	var winLabel = Global.CustomLabel.instance()
	winLabel.position = Vector2(340, 64)
	winLabel.text = toastText
	winLabel.fontSize = 2
	winLabel.outline = true
	winLabel.aliveTime = 3
	winLabel.alignment = Label.ALIGN_CENTER
	get_tree().get_root().add_child(winLabel)
	yield(get_tree().create_timer(3), "timeout")
	Global.goToMap()
