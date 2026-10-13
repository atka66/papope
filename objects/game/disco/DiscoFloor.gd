extends Node2D

const orCols: Array[Color] = [Color("0042e1"), Color("a71cc8"), Color("e600a3"), Color("ff007a"), Color("ff4853"), Color("ff7b30"), Color("ffa710")]

# online: the host rolls pattern + seed per cycle and broadcasts; everyone
# (host included) runs the routine against discoRng so all screens show the
# same light show. This matters on nightclub: darkened players are only
# visible under lit tiles, so a divergent show would be unfair.
var discoRng := RandomNumberGenerator.new()
var _current := [-1, 0]
var _gen := 0

# Writes from a superseded cycle go here instead of the tiles: a newer
# broadcast instantly takes over the floor, old coroutines fade harmlessly.
class TileSink:
	func anim_pulse(_c): pass
	func on(_c): pass
	func off(): pass
var _sink := TileSink.new()

func _ready():
	initPlayerTiles()
	if Net.isOnline and not Net.isHost:
		# The host's broadcast may predate our load; ask for the current
		# cycle to be unicast back (host also pushes on join, see Net).
		Net.request_disco()
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

func adoptCycle(idx: int, cycleSeed: int) -> void:
	# Newest broadcast wins instantly: bump the generation so any in-flight
	# cycle's tile writes sink, then run the fresh cycle (lag stays ~RTT).
	if not is_inside_tree():
		return
	_gen += 1
	_runCycle(idx, cycleSeed, _gen)

func GT(g: int, row: int, col: int) -> Object:
	if g == _gen:
		return getTile(row, col)
	return _sink

func playRandomAnim():
	# Pattern + colors vary per cycle; online the host's roll is broadcast so
	# every screen runs the identical show from the same seed.
	var idx := randi() % 6
	var cycleSeed := randi()
	if Net.isOnline:
		_current = [idx, cycleSeed]
		Net.disco_cycle(idx, cycleSeed)
		_gen += 1
	await _runCycle(idx, cycleSeed, _gen)
	playRandomAnim()

func _runCycle(idx: int, cycleSeed: int, g: int) -> void:
	discoRng.seed = cycleSeed
	match idx:
		0:
			await square(g)
		1:
			await diamond(g)
		2:
			await brazilWave(g)
		3:
			await brazilWaveDiagonal(g)
		4:
			await colorAllRandomSync(g)
		_:
			await scanLine(g)
	for i in range(1, 6):
		for j in range(1, 6):
			GT(g,i, j).off()

# animations

func square(g: int): # done
	var waitTime = 0.2
	for n in range(8):
		var color = _pickCol()
		GT(g,3, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		GT(g,2, 2).anim_pulse(color)
		GT(g,2, 3).anim_pulse(color)
		GT(g,2, 4).anim_pulse(color)
		GT(g,3, 2).anim_pulse(color)
		GT(g,3, 4).anim_pulse(color)
		GT(g,4, 2).anim_pulse(color)
		GT(g,4, 3).anim_pulse(color)
		GT(g,4, 4).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		GT(g,1, 1).anim_pulse(color)
		GT(g,1, 2).anim_pulse(color)
		GT(g,1, 3).anim_pulse(color)
		GT(g,1, 4).anim_pulse(color)
		GT(g,1, 5).anim_pulse(color)
		GT(g,2, 1).anim_pulse(color)
		GT(g,2, 5).anim_pulse(color)
		GT(g,3, 1).anim_pulse(color)
		GT(g,3, 5).anim_pulse(color)
		GT(g,4, 1).anim_pulse(color)
		GT(g,4, 5).anim_pulse(color)
		GT(g,5, 1).anim_pulse(color)
		GT(g,5, 2).anim_pulse(color)
		GT(g,5, 3).anim_pulse(color)
		GT(g,5, 4).anim_pulse(color)
		GT(g,5, 5).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout

func diamond(g: int): # done
	var waitTime = 0.1
	for n in range(9):
		var color = _pickCol()
		GT(g,3, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		GT(g,2, 3).anim_pulse(color)
		GT(g,3, 2).anim_pulse(color)
		GT(g,3, 4).anim_pulse(color)
		GT(g,4, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		GT(g,1, 3).anim_pulse(color)
		GT(g,2, 2).anim_pulse(color)
		GT(g,2, 4).anim_pulse(color)
		GT(g,3, 1).anim_pulse(color)
		GT(g,3, 5).anim_pulse(color)
		GT(g,4, 2).anim_pulse(color)
		GT(g,4, 4).anim_pulse(color)
		GT(g,5, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		GT(g,1, 2).anim_pulse(color)
		GT(g,1, 4).anim_pulse(color)
		GT(g,2, 1).anim_pulse(color)
		GT(g,2, 5).anim_pulse(color)
		GT(g,4, 1).anim_pulse(color)
		GT(g,4, 5).anim_pulse(color)
		GT(g,5, 2).anim_pulse(color)
		GT(g,5, 4).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		GT(g,1, 1).anim_pulse(color)
		GT(g,1, 5).anim_pulse(color)
		GT(g,5, 1).anim_pulse(color)
		GT(g,5, 5).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout

func brazilWave(g: int): # done
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
				GT(g,ix, jx).anim_pulse(color)
			await get_tree().create_timer(0.1).timeout

func brazilWaveDiagonal(g: int): # done
	var waitTime = 0.1
	for n in range(5):
		var color = _pickCol()
		GT(g,1, 1).anim_pulse(color) # i = 1; j = 1
		await get_tree().create_timer(waitTime).timeout
		GT(g,1, 2).anim_pulse(color) # i = 2; j = 1
		GT(g,2, 1).anim_pulse(color) # i = 2; j = 2
		await get_tree().create_timer(waitTime).timeout
		GT(g,1, 3).anim_pulse(color) # i = 3; j = 1
		GT(g,2, 2).anim_pulse(color) # i = 3; j = 2
		GT(g,3, 1).anim_pulse(color) # i = 3; j = 3
		await get_tree().create_timer(waitTime).timeout
		GT(g,1, 4).anim_pulse(color) # i = 4; j = 1
		GT(g,2, 3).anim_pulse(color) # i = 4; j = 2
		GT(g,3, 2).anim_pulse(color) # i = 4; j = 3
		GT(g,4, 1).anim_pulse(color) # i = 4; j = 4
		await get_tree().create_timer(waitTime).timeout
		GT(g,1, 5).anim_pulse(color) # i = 5; j = 1
		GT(g,2, 4).anim_pulse(color) # i = 5; j = 2
		GT(g,3, 3).anim_pulse(color) # i = 5; j = 3
		GT(g,4, 2).anim_pulse(color) # i = 5; j = 4
		GT(g,5, 1).anim_pulse(color) # i = 5; j = 5
		await get_tree().create_timer(waitTime).timeout
		GT(g,2, 5).anim_pulse(color)
		GT(g,3, 4).anim_pulse(color)
		GT(g,4, 3).anim_pulse(color)
		GT(g,5, 2).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		GT(g,3, 5).anim_pulse(color)
		GT(g,4, 4).anim_pulse(color)
		GT(g,5, 3).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		GT(g,4, 5).anim_pulse(color)
		GT(g,5, 4).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout
		GT(g,5, 5).anim_pulse(color)
		await get_tree().create_timer(waitTime).timeout

func colorAllRandomSync(g: int): # done
	for n in range(8):
		for i in range(1, 6):
			for j in range(1, 6):
				GT(g,i, j).on(_pickCol())
		await get_tree().create_timer(0.6).timeout

func scanLine(g: int): # done
	var rainbowLine = discoRng.randi() % 2 == 0
	for n in range(6):
		var color = _pickCol()
		for i in range(1, 6):
			if rainbowLine:
				color = _pickCol()
			for j in range(1, 6):
				GT(g,i, j).anim_pulse(color)
				await get_tree().create_timer(0.02).timeout
