extends Node2D

var velocity = Vector2.ZERO
var gravity = 2

func _ready():
	velocity = Vector2(randf_range(-4.0, 4.0), randf_range(-15.0, -20.0))
	rotation = velocity.x / 10

func _process(delta):
	var step: float = delta * 60.0
	position += velocity * step
	velocity.y += gravity * step
	if velocity.y > 0:
		rotation *= pow(1.1, step)
