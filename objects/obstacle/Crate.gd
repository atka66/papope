extends StaticBody2D

var hp = 6

func destroy(impulse):
	for i in range(15):
		var particle = Res.CrateParticle.instance()
		particle.position = position + Vector2((randi() % 32) - 16, (randi() % 32) - 16)
		particle.impulse(impulse)
		get_parent().add_child(particle)
	queue_free()
