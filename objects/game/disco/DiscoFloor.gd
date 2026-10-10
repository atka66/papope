extends Node2D

const orCols: Array[Color] = [Color("0042e1"), Color("a71cc8"), Color("e600a3"), Color("ff007a"), Color("ff4853"), Color("ff7b30"), Color("ffa710")]

# online: the host rolls pattern + seed per cycle and broadcasts; everyone
# (host included) runs the routine against discoRng so all screens show the
# same light show. This matters on nightclub: darkened players are only
# visible under lit tiles, so a divergent show would be unfair.
var discoRng := RandomNumberGenerator.new()

func _ready():
	initPlayerTiles()
	if Net.isOnline and not multiplayer.is_server():
		return # guests run cycles via Net.disco_cycle
	playRandomAnim()

func _pickCol() -> Color:
	return orCols[discoRng.randi_range(0, orCols.size() - 1)]

func initPlayerTiles():
	for i in range(4):
		if Global.playersJoined[i]:
			getTile(0, i + 1).anim_in(Global.TEAM_COLORS[Global.playersTeam[i]].darkened(0.3))

func getTile(row: int, col: int) -> Object:
	return get_node('DiscoTile' + str(row) + str(col))

func playRandomAnim():
	# Pattern + colors vary per cycle; online the host's roll is broadcast so
	# every screen runs the identical show from the same seed.
	var idx := randi() % 7
	var seed := randi()
	if Net.isOnline:
		Net.disco_cycle.rpc(idx, seed)
	await _runCycle(idx, seed)
	playRandomAnim()

func _runCycle(idx: int, seed: int) -> void:
	discoRng.seed = seed
	match idx:
		0:
			await square()
		1:
			await diamond()
		2:
			await brazilWave()
		3:
			await brazilWaveDiagonal()
		4:
			await colorAllRandomSync()
		5:
			await sparkleRandom()
		_:
			await scanLine()
	for i in range(1, 6):
		for j in range(1, 6):
			getTile(i, j).off()

# animations

func square(): # done
	var waitTime = 0.2
	for n in range(8):
		var color = _pickCol()
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
		var color = _pickCol()
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
	var inverted = discoRng.randi() % 2 == 0
	var vertical = discoRng.randi() % 2 == 0
	for n in range(8):
		var color = _pickCol()
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
		var color = _pickCol()
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
				getTile(i, j).on(_pickCol())
		await get_tree().create_timer(0.6).timeout

func sparkleRandom(): #done
	for n in range(75):
		getTile(discoRng.randi_range(1, 5), discoRng.randi_range(1, 5)).anim_pulse(_pickCol())
		await get_tree().create_timer(0.05).timeout

func scanLine(): # done
	var rainbowLine = discoRng.randi() % 2 == 0
	for n in range(6):
		var color = _pickCol()
		for i in range(1, 6):
			if rainbowLine:
				color = _pickCol()
			for j in range(1, 6):
				getTile(i, j).anim_pulse(color)
				await get_tree().create_timer(0.02).timeout
