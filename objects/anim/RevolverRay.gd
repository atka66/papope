extends Node2D

@export var length: int = 0

func _ready():
	$Ray.add_point(Vector2(length, 0))
	await $Audio.finished
	queue_free()
