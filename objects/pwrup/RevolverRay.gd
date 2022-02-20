extends Node2D

export(int) var length = 0

func _ready():
	$MuzzleFlashPar1.emitting = true
	$MuzzleFlashPar2.emitting = true
	$Audio.play()
	$Line2D.add_point(Vector2(length, 0))
	yield($Audio, "finished")
	queue_free()
