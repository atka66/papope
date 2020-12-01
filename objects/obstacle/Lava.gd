extends Area2D

func _ready():
	$Particles.scale = Vector2.ONE / scale
	$Particles.emission_rect_extents *= Vector2(scale.x, scale.y)
	$Particles.amount *= scale.x * scale.y

func _on_Lava_body_entered(body):
	if body.is_in_group('players'):
		body.get_node('AudioInLava').play()
		if body.alive:
			body.get_node("SmokeParticles").emitting = true
			body.contactsLava = true


func _on_Lava_body_exited(body):
	if body.is_in_group('players'):
		body.get_node('AudioInLava').stop()
		if body.alive:
			body.get_node("SmokeParticles").emitting = false
			body.contactsLava = false
