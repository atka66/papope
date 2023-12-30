extends Node2D

func _ready():
	$Particles.restart()
	if randi() % 3 == 0:
		$Audio.stream = Res.AudioRevolverRicochet.pick_random()
		$Audio.play()
	await get_tree().create_timer(5.0).timeout
	queue_free()
