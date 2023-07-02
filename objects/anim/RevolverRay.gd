extends Node2D

@export var length: int = 0

func _ready():
	$Ray.add_point(Vector2(length, 0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
