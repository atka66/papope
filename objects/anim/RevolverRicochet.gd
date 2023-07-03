extends Node2D

func _ready():
	$Particles.restart()
	$Audio.stream = Res.AudioRevolverRicochet.pick_random()
	$Audio.play()
	await $Audio.finished
	queue_free()
