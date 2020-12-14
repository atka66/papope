extends Area2D

var speed = 2
var prevNode = null
var destNode = null
var moving = false
const GHOST_COLORS = [Color.red, Color.pink, Color.aqua, Color.coral]

func _ready():
	position = destNode.position
	$Container/Body.modulate = GHOST_COLORS[randi() % len(GHOST_COLORS)]
	$AudioAppear.play()

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
			var candidateNode = null
			if len(destNode.neighbors) > 1:
				var randomNode = prevNode
				while randomNode == prevNode:
					var randomNodeId = destNode.neighbors[randi() % len(destNode.neighbors)]
					randomNode = get_parent().get_node('GhostPathNode' + str(randomNodeId))
				candidateNode = randomNode
			else:
				candidateNode = get_parent().get_node('GhostPathNode' + str(destNode.neighbors[0]))
			prevNode = destNode
			destNode = candidateNode
		else:
			position = position.move_toward(destNode.position, speed)


func _on_Anim_animation_finished(anim_name):
	if anim_name == 'appear':
		moving = true
		$AudioWalk.play()
		$Anim.play("move")


func _on_AudioWalk_finished():
	if moving:
		$AudioWalk.play()
