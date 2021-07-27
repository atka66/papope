extends StaticBody2D

var hp = 6

func destroy(impulse):
	for i in range(15):
		var actualImpulse = Vector2(
			(impulse.x + (randi() % 100) - 50) * (randi() % 10), 
			(impulse.y + (randi() % 100) - 50) * (randi() % 10)
		)
		var particle = Res.CrateParticle.instance()
		particle.position = position + Vector2((randi() % 32) - 16, (randi() % 32) - 16)
		particle.apply_central_impulse(actualImpulse)
		particle.add_torque((randi() % 300) - 150)
		get_parent().add_child(particle)
	queue_free()
