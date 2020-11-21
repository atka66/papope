extends Area2D

func _on_WaterTrigger_body_entered(body):
	if body.is_in_group('players'):
		if !body.fallWater:
			body.fallWater = true
			body.gravity_scale = 30
			var velX = 0.5
			if body.global_position.x < 340:
				velX *= -1
			body.apply_central_impulse(Vector2(velX, -1) * 300)
			yield(get_tree().create_timer(0.7), "timeout")
			if !Global.playersFrozen:
				body.hp = 0
			body.gravity_scale = 0
			body.fallWater = false
