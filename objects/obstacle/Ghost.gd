extends Area2D

var speed = 2
var destNode = null
const GHOST_COLORS = [Color.red, Color.pink, Color.aqua, Color.coral]

func _ready():
	position = destNode.position
	$Body.modulate = GHOST_COLORS[randi() % len(GHOST_COLORS)]

func _on_Ghost_body_entered(body):
	if body.is_in_group('players') && !Global.playersFrozen:
		body.get_node('AudioSlipInWater').play()
		body.hp = 0
		Global.registerAchievement(body.playerId, Global.AchiEnum.SPOOKED)
	if body.is_in_group('dynamites'):
		body.explode()
		Global.incrementStat(body.originPlayerId, Global.StatEnum.GHOST_KILL, 1)
		die()

func die():
	var deadGhost = Res.DeadGhost.instance()
	deadGhost.position = global_position
	get_parent().add_child(deadGhost)
	var spawn = get_parent().get_node('MapController').initGhostSpawn()
	queue_free()

func _process(delta):
	if destNode.position.x > position.x:
		$Eyes.frame = 0
	if destNode.position.y < position.y:
		$Eyes.frame = 1
	if destNode.position.x < position.x:
		$Eyes.frame = 2
	if destNode.position.y > position.y:
		$Eyes.frame = 3

	if position == destNode.position:
		var randomNodeId = destNode.neighbors[randi() % len(destNode.neighbors)]
		destNode = get_parent().get_node('GhostPathNode' + str(randomNodeId))
	else:
		position = position.move_toward(destNode.position, speed)
