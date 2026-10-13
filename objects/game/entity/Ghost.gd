extends Area2D

const GHOST_COLORS = [Color.RED, Color.PINK, Color.AQUA, Color.CORAL]

var speed: float = ProjectSettings.get("papope/ghost_speed")
@export var moving: bool = false

var prevNode = null
var destNode = null

# online: host simulates, guests interpolate snapshots; color is host-rolled
var netColorIdx: int = -1
const NET_INTERP_DELAY := 0.1
var netSnaps: Array = []

func _ready():
	position = destNode.position
	if netColorIdx >= 0:
		$Container/Body.modulate = GHOST_COLORS[netColorIdx % GHOST_COLORS.size()]
	else:
		$Container/Body.modulate = GHOST_COLORS.pick_random()

func _process(delta):
	if Net.isOnline and not Net.isHost:
		_interpGhost()
		return
	if moving:
		if destNode.position.x > position.x:
			$Container/Eyes.frame = 0
		if destNode.position.y < position.y:
			$Container/Eyes.frame = 1
		if destNode.position.x < position.x:
			$Container/Eyes.frame = 2
		if destNode.position.y > position.y:
			$Container/Eyes.frame = 3

		if position == destNode.position:
			var neighbors = destNode.get_meta('neighbors')
			var candidateNode = null
			if neighbors == null || neighbors.is_empty(): # incorrectly configured neighbors
				candidateNode = prevNode
			elif len(neighbors) == 1: # dead end
				candidateNode = get_parent().get_node('GhostPath/Node' + str(neighbors[0]))
			else:
				var randomNode = prevNode
				while randomNode == prevNode:
					var randomNodeId = neighbors.pick_random()
					randomNode = get_parent().get_node('GhostPath/Node' + str(randomNodeId))
				candidateNode = randomNode
			prevNode = destNode
			
			destNode = candidateNode
		else:
			position = position.move_toward(destNode.position, speed * delta)

func _input(event):
	if Global.DEBUG and !Net.isOnline:
		if Input.is_action_just_pressed("test3"):
			die(null)

func _interpGhost() -> void:
	# Same delayed-snapshot interpolation as remote players.
	if netSnaps.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	var rt := now - NET_INTERP_DELAY
	while netSnaps.size() > 2:
		var d: Dictionary = netSnaps[1]
		if float(d.get("t", 0.0)) > rt:
			break
		netSnaps.pop_front()
	var a: Dictionary = netSnaps[0]
	var prev := global_position
	if netSnaps.size() < 2:
		var pa0: Vector2 = a["pos"]
		global_position = global_position.lerp(pa0, 0.5)
	else:
		var b: Dictionary = netSnaps[1]
		var ta := float(a.get("t", 0.0))
		var tb := float(b.get("t", 0.0))
		var pa: Vector2 = a["pos"]
		var pb: Vector2 = b["pos"]
		if rt <= ta:
			global_position = pa
		elif rt >= tb:
			var over := minf(rt - tb, 0.05)
			var vb: Vector2 = b.get("vel", Vector2.ZERO)
			global_position = pb + vb * over
		else:
			var f := clampf((rt - ta) / maxf(tb - ta, 0.001), 0.0, 1.0)
			global_position = pa.lerp(pb, f)
	var step := global_position - prev
	if absf(step.x) > absf(step.y):
		$Container/Eyes.frame = 0 if step.x > 0.0 else 2
	elif step.length() > 0.01:
		$Container/Eyes.frame = 3 if step.y > 0.0 else 1

func die(inflictorId):
	# Online ghost deaths are host-authorized; guests mirror via Net.ghost_died.
	if Net.isOnline and not Net.isHost:
		return
	if inflictorId != null:
		Global.incrementStat(inflictorId, Global.StatEnum.GHOST_KILL, 1)
	var deadGhost = Res.DeadGhostObject.instantiate()
	deadGhost.position = global_position
	get_parent().add_child(deadGhost)
	if Net.isOnline:
		Net.ghost_died()
	Global.initGhostSpawn()
	queue_free()

func mirrorDeath() -> void:
	# Guest-side visual death (stats/respawn are host-driven).
	var deadGhost = Res.DeadGhostObject.instantiate()
	deadGhost.position = global_position
	get_parent().add_child(deadGhost)
	queue_free()

func push_snapshot(pos: Vector2) -> void:
	var vel := Vector2.ZERO
	if not netSnaps.is_empty():
		var last: Dictionary = netSnaps[netSnaps.size() - 1]
		var lp: Vector2 = last.get("pos", pos)
		vel = (pos - lp) / 0.1
	netSnaps.append({"t": Time.get_ticks_msec() / 1000.0, "pos": pos, "vel": vel})
	while netSnaps.size() > 4:
		netSnaps.pop_front()

func getShot(playerId: int, normal: Vector2) -> void:
	die(playerId)

func getTrapped(playerId: int) -> void:
	die(playerId)

func getWhipped(playerId: int, normal: Vector2) -> void:
	die(playerId)


func _on_body_entered(body):
	if Net.isOnline and not Net.isHost:
		return
	if body.is_in_group('players') && body.alive && !Global.playersFrozen:
		body.get_node('AudioScared').play()
		body.die(Global.DeathEnum.GHOST)
		Global.registerAchievement(body.playerId, Global.AchiEnum.SPOOKED)
	if body.is_in_group('dynamites'):
		body.explode()
		die(body.origin.playerId)
