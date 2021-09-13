extends Area2D

export(Global.DeathEnum) var deathType = Global.DeathEnum.WATER

func _on_FallTrigger_body_entered(body):
	if body.is_in_group('players'):
		if !body.fallWater:
			body.get_node('AudioSlipInWater').play()
			body.fallWater = true
			body.gravity_scale = 30
			var vector = -body.linear_velocity
			var vel = Vector2(0.7, -1)
			if body.global_position.x < 340:
				vel.x *= -1
			body.apply_central_impulse(vector + (vel * 500))
			yield(get_tree().create_timer(0.7), "timeout")
			body.get_node('AudioFellwater').play()
			if !Global.playersFrozen:
				body.die(deathType)
			body.gravity_scale = 0
