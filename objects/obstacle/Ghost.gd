extends Area2D

var velocity = Vector2(2, 0)

func _ready():
	invert()
	
func invert():
	yield(get_tree().create_timer(2.0), "timeout")
	velocity *= -1
	var rerun = invert()

func _on_Ghost_body_entered(body):
	if body.is_in_group('players'):
		body.get_node('AudioSlipInWater').play()
		body.hp = 0
	if body.is_in_group('dynamites'):
		body.explode()
		die()

func die():
	var deadGhost = Res.DeadGhost.instance()
	deadGhost.position = global_position
	get_parent().add_child(deadGhost)
	queue_free()

func _process(delta):
	position += velocity
