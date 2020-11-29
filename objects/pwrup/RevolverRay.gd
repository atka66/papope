extends Node2D

export(int) var length = 0

func _ready():
	$Audio.play()
	$Line2D.add_point(Vector2(length, 0))
	yield(get_tree().create_timer(0.02, false), "timeout")
	hide()
	yield($Audio, "finished")
	queue_free()
