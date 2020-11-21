extends Node2D

func _ready():
	$Phase1.hide()
	$Phase2.hide()
	$Phase2/CollisionShape2D.disabled = true
	var loop = _rayLoop()

func _rayLoop():
	yield(get_tree().create_timer(15.0), "timeout")
	$Phase1.show()
	$Phase1/Phase1Anim.play()
	yield(get_tree().create_timer(0.5), "timeout")
	$Phase1.hide()
	$Phase2.show()
	$Phase2/CollisionShape2D.disabled = false
	yield(get_tree().create_timer(4.5), "timeout")
	$Phase2.hide()
	$Phase2/CollisionShape2D.disabled = true
	var rerun = _rayLoop()


func _on_Phase2_body_entered(body):
	if body.is_in_group('players'):
		body.hurt(25)
		var vector = Vector2(-body.linear_velocity.x, 0)
		
		var vel = Vector2(1, 0)
		if body.global_position.x < 340:
			vel.x *= -1
		body.apply_central_impulse(vector + (vel * 800))
	if body.is_in_group('dynamites'):
		body.explode()
