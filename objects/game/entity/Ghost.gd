extends Area2D

# TODO kill the player on contact

const GHOST_COLORS = [Color.RED, Color.PINK, Color.AQUA, Color.CORAL]

var speed: float = ProjectSettings.get("papope/ghost_speed")
@export var moving: bool = false

var prevNode = null
var destNode = null

func _ready():
	position = destNode.position
	$Container/Body.modulate = GHOST_COLORS[randi() % len(GHOST_COLORS)]

func _process(delta):
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
					var randomNodeId = neighbors[randi() % len(neighbors)]
					randomNode = get_parent().get_node('GhostPath/Node' + str(randomNodeId))
				candidateNode = randomNode
			prevNode = destNode
			destNode = candidateNode
		else:
			position = position.move_toward(destNode.position, speed)

func _input(event):
	if Global.DEBUG:
		if Input.is_action_just_pressed("test3"):
			die()

func die():
	var deadGhost = Res.DeadGhostObject.instantiate()
	deadGhost.position = global_position
	get_parent().add_child(deadGhost)
	Global.initGhostSpawn()
	queue_free()

func getShot(playerId: int, normal: Vector2) -> void:
	die()

func getTrapped(playerId: int) -> void:
	#TODO ghost kill achievement?
	die()

func getWhipped(playerId: int, normal: Vector2) -> void:
	die()


func _on_body_entered(body):
	if body.is_in_group('players') && body.alive && !Global.playersFrozen:
		body.get_node('AudioScared').play()
		body.die(Global.DeathEnum.GHOST)
		# TODO Global.registerAchievement(body.playerId, Global.AchiEnum.SPOOKED)
	if body.is_in_group('dynamites'):
		body.explode()
		# TODO Global.incrementStat(body.originPlayerId, Global.StatEnum.GHOST_KILL, 1)
		die()
