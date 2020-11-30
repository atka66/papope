extends Area2D

func _ready():
	$Particles.process_material = preload("res://resources/LavaPar.tres").duplicate()
	$Particles.scale = Vector2.ONE / scale
	$Particles.process_material.emission_box_extents *= Vector3(scale.x, scale.y, 0)
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
