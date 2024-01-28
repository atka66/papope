extends Node2D

const orCols: Array[Color] = [Color("0042e1"), Color("a71cc8"), Color("e600a3"), Color("ff007a"), Color("ff4853"), Color("ff7b30"), Color("ffa710")]

func _ready():
	initPlayerTiles()
	playRandomAnim()

func initPlayerTiles():
	for i in range(4):
		if Global.playersJoined[i]:
			getTile(0, i + 1).anim_in(Global.TEAM_COLORS[Global.playersTeam[i]].darkened(0.3))

func getTile(row: int, col: int) -> Object:
	return get_node('DiscoTile' + str(row) + str(col))

func playRandomAnim():
	await [square, diamond, brazilWave, brazilWaveDiagonal, colorAllRandomSync, sparkleRandom, scanLine].pick_random().call()
	for i in range(1, 6):
		for j in range(1, 6):
			getTile(i, j).off()
	playRandomAnim()

# animations

func square(): # done
	var waitTime = 0.2
	for n in range(8):
		var color = orCols.pick_random()
		getTile(3, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		getTile(2, 2).anim_pulse(color)
		getTile(2, 3).anim_pulse(color)
		getTile(2, 4).anim_pulse(color)
		getTile(3, 2).anim_pulse(color)
		getTile(3, 4).anim_pulse(color)
		getTile(4, 2).anim_pulse(color)
		getTile(4, 3).anim_pulse(color)
		getTile(4, 4).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		getTile(1, 1).anim_pulse(color)
		getTile(1, 2).anim_pulse(color)
		getTile(1, 3).anim_pulse(color)
		getTile(1, 4).anim_pulse(color)
		getTile(1, 5).anim_pulse(color)
		getTile(2, 1).anim_pulse(color)
		getTile(2, 5).anim_pulse(color)
		getTile(3, 1).anim_pulse(color)
		getTile(3, 5).anim_pulse(color)
		getTile(4, 1).anim_pulse(color)
		getTile(4, 5).anim_pulse(color)
		getTile(5, 1).anim_pulse(color)
		getTile(5, 2).anim_pulse(color)
		getTile(5, 3).anim_pulse(color)
		getTile(5, 4).anim_pulse(color)
		getTile(5, 5).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout

func diamond(): # done
	var waitTime = 0.1
	for n in range(9):
		var color = orCols.pick_random()
		getTile(3, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		getTile(2, 3).anim_pulse(color)
		getTile(3, 2).anim_pulse(color)
		getTile(3, 4).anim_pulse(color)
		getTile(4, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		getTile(1, 3).anim_pulse(color)
		getTile(2, 2).anim_pulse(color)
		getTile(2, 4).anim_pulse(color)
		getTile(3, 1).anim_pulse(color)
		getTile(3, 5).anim_pulse(color)
		getTile(4, 2).anim_pulse(color)
		getTile(4, 4).anim_pulse(color)
		getTile(5, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		getTile(1, 2).anim_pulse(color)
		getTile(1, 4).anim_pulse(color)
		getTile(2, 1).anim_pulse(color)
		getTile(2, 5).anim_pulse(color)
		getTile(4, 1).anim_pulse(color)
		getTile(4, 5).anim_pulse(color)
		getTile(5, 2).anim_pulse(color)
		getTile(5, 4).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		getTile(1, 1).anim_pulse(color)
		getTile(1, 5).anim_pulse(color)
		getTile(5, 1).anim_pulse(color)
		getTile(5, 5).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout

func brazilWave(): # done
	var inverted = randi() % 2 == 0
	var vertical = randi() % 2 == 0
	for n in range(8):
		var color = orCols.pick_random()
		for i in range(1, 6):
			for j in range(1, 6):
				var ix
				var jx
				if vertical:
					ix = j
					jx = i
				else:
					ix = i
					jx = j
				if inverted:
					ix = 6 - ix
					jx = 6 - jx
				getTile(ix, jx).anim_pulse(color)
			await get_tree().create_timer(0.1).timeout

func brazilWaveDiagonal(): # done
	var waitTime = 0.1
	for n in range(5):
		var color = orCols.pick_random()
		getTile(1, 1).anim_pulse(color) # i = 1; j = 1
		await get_tree().create_timer(waitTime).timeout
		getTile(1, 2).anim_pulse(color) # i = 2; j = 1
		getTile(2, 1).anim_pulse(color) # i = 2; j = 2
		await get_tree().create_timer(waitTime).timeout
		getTile(1, 3).anim_pulse(color) # i = 3; j = 1
		getTile(2, 2).anim_pulse(color) # i = 3; j = 2
		getTile(3, 1).anim_pulse(color) # i = 3; j = 3
		await get_tree().create_timer(waitTime).timeout
		getTile(1, 4).anim_pulse(color) # i = 4; j = 1
		getTile(2, 3).anim_pulse(color) # i = 4; j = 2
		getTile(3, 2).anim_pulse(color) # i = 4; j = 3
		getTile(4, 1).anim_pulse(color) # i = 4; j = 4
		await get_tree().create_timer(waitTime).timeout
		getTile(1, 5).anim_pulse(color) # i = 5; j = 1
		getTile(2, 4).anim_pulse(color) # i = 5; j = 2
		getTile(3, 3).anim_pulse(color) # i = 5; j = 3
		getTile(4, 2).anim_pulse(color) # i = 5; j = 4
		getTile(5, 1).anim_pulse(color) # i = 5; j = 5
		await get_tree().create_timer(waitTime).timeout
		getTile(2, 5).anim_pulse(color)
		getTile(3, 4).anim_pulse(color)
		getTile(4, 3).anim_pulse(color)
		getTile(5, 2).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		getTile(3, 5).anim_pulse(color)
		getTile(4, 4).anim_pulse(color)
		getTile(5, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		getTile(4, 5).anim_pulse(color)
		getTile(5, 4).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		getTile(5, 5).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout

func colorAllRandomSync(): # done
	for n in range(8):
		for i in range(1, 6):
			for j in range(1, 6):
				getTile(i, j).on(orCols.pick_random())
		await get_tree().create_timer(0.6).timeout

func sparkleRandom(): #done
	for n in range(75):
		getTile(randi_range(1, 5), randi_range(1, 5)).anim_pulse(orCols.pick_random())
		await get_tree().create_timer(0.05).timeout

func scanLine(): # done
	var rainbowLine = randi() % 2 == 0
	for n in range(6):
		var color = orCols.pick_random()
		for i in range(1, 6):
			if rainbowLine:
				color = orCols.pick_random()
			for j in range(1, 6):
				getTile(i, j).anim_pulse(color)
				await get_tree().create_timer(0.02).timeout
