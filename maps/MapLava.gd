extends Node2D

func _ready():
	var mapLabel = Global.CustomLabel.instance()
	mapLabel.position.x = 64
	mapLabel.position.y = 288
	mapLabel.text = Global.options['map'][Global.optionsSelected['map']]
	mapLabel.fontSize = 6
	mapLabel.outline = true
	mapLabel.aliveTime = 2
	mapLabel.alignment = Label.ALIGN_LEFT
	add_child(mapLabel)
	var a = initSpawnPwrup()
	yield(get_tree().create_timer(2), "timeout")
	for i in range(4):
		if Global.playersJoined[i]:
			var player = Global.Player.instance()
			player.position = get_node("PlayerSpawner" + str(i)).position
			player.playerId = i
			add_child(player)
			yield(get_tree().create_timer(0.25), "timeout")

func initSpawnPwrup():
	yield(get_tree().create_timer(10), "timeout")
	spawnPwrup()

func spawnPwrup():
	var pwrup = Global.Pwrup.instance()
	var spawner = getRandomSpawner()
	pwrup.position = spawner.position
	add_child(pwrup)
	yield(get_tree().create_timer(6), "timeout")
	var rerun = spawnPwrup()

func getRandomSpawner():
	var spawners = []
	for child in get_children():
		if child.is_in_group("spawners"):
			spawners.append(child)
	return spawners[randi() % len(spawners)]
