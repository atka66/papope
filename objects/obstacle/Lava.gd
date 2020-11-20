extends Area2D


func _on_Lava_body_entered(body):
	if body.is_in_group('players'):
		if body.alive:
			body.get_node("SmokeParticles").emitting = true
			body.contactsLava = true


func _on_Lava_body_exited(body):
	if body.is_in_group('players'):
		if body.alive:
			body.get_node("SmokeParticles").emitting = false
			body.contactsLava = false
