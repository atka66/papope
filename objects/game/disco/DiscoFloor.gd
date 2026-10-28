extends Node2D

const orCols: Array[Color] = [Color("0042e1"), Color("a71cc8"), Color("e600a3"), Color("ff007a"), Color("ff4853"), Color("ff7b30"), Color("ffa710")]

# Lit grid: rows 1..5, cols 0..6. Cols 0 and 6 are the extension columns that
# bridge the 5x5 core to the row-0 spawn pads (nightclub). R/C is the pattern
# centre; every routine below is written against these bounds.
const R_MIN := 1
const R_MAX := 5
const C_MIN := 0
const C_MAX := 6
const R := 3
const C := 3

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
	# Pads (row 0) stay lit for the whole round — the per-cycle cleanup only
	# touches rows 1..5 — so every pad gets a light even with an empty slot:
	# an unlit pad is a reachable square inside the walled floor, i.e. a
	# permanent hiding spot.
	for i in range(4):
		var col = Color(0.2, 0.2, 0.2, 1.0)
		if Global.playersJoined[i]:
			col = Global.TEAM_COLORS[Global.playersTeam[i]].darkened(0.3)
		getTile(0, i + 1).anim_in(col)

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
	for i in range(R_MIN, R_MAX + 1):
		for j in range(C_MIN, C_MAX + 1):
			GT(g,i, j).off()

# animations

func square(g: int): # done
	var waitTime = 0.2
	for n in range(8):
		var color = _pickCol()
		# Chebyshev rings: 0 = centre, 1 = 3x3, 2 = 5x5 border, 3 = the two
		# extension columns (rows out of range are simply never matched).
		for d in range(4):
			for i in range(R_MIN, R_MAX + 1):
				for j in range(C_MIN, C_MAX + 1):
					if maxi(absi(i - R), absi(j - C)) == d:
						GT(g,i, j).anim_pulse(color)
			await get_tree().create_timer(waitTime).timeout

func diamond(g: int): # done
	var waitTime = 0.1
	for n in range(9):
		var color = _pickCol()
		# Manhattan rings around the centre, widest = the extension columns.
		for d in range(6):
			for i in range(R_MIN, R_MAX + 1):
				for j in range(C_MIN, C_MAX + 1):
					if absi(i - R) + absi(j - C) == d:
						GT(g,i, j).anim_pulse(color)
			await get_tree().create_timer(waitTime).timeout

func brazilWave(g: int): # done
	var inverted = discoRng.randi() % 2 == 0
	var vertical = discoRng.randi() % 2 == 0
	var waitTime = 0.1
	for n in range(8):
		var color = _pickCol()
		if vertical:
			# light one whole column at a time, sweeping across
			for j in range(C_MIN, C_MAX + 1):
				var col = ((C_MIN + C_MAX) - j) if inverted else j
				for i in range(R_MIN, R_MAX + 1):
					GT(g,i, col).anim_pulse(color)
				await get_tree().create_timer(waitTime).timeout
		else:
			# light one whole row at a time, sweeping down/up
			for i in range(R_MIN, R_MAX + 1):
				var row = ((R_MIN + R_MAX) - i) if inverted else i
				for j in range(C_MIN, C_MAX + 1):
					GT(g,row, j).anim_pulse(color)
				await get_tree().create_timer(waitTime).timeout

func brazilWaveDiagonal(g: int): # done
	var waitTime = 0.1
	for n in range(5):
		var color = _pickCol()
		# anti-diagonals: every tile where i + j == s
		for s in range(R_MIN + C_MIN, R_MAX + C_MAX + 1):
			for i in range(R_MIN, R_MAX + 1):
				var j = s - i
				if j >= C_MIN and j <= C_MAX:
					GT(g,i, j).anim_pulse(color)
			await get_tree().create_timer(waitTime).timeout

func colorAllRandomSync(g: int): # done
	for n in range(8):
		for i in range(R_MIN, R_MAX + 1):
			for j in range(C_MIN, C_MAX + 1):
				GT(g,i, j).on(_pickCol())
		await get_tree().create_timer(0.6).timeout

func scanLine(g: int): # done
	var rainbowLine = discoRng.randi() % 2 == 0
	for n in range(6):
		var color = _pickCol()
		for i in range(R_MIN, R_MAX + 1):
			if rainbowLine:
				color = _pickCol()
			for j in range(C_MIN, C_MAX + 1):
				GT(g,i, j).anim_pulse(color)
				await get_tree().create_timer(0.02).timeout
