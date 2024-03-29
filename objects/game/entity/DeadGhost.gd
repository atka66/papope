extends Node2D

var velocity = Vector2.ZERO
var gravity = 2

func _ready():
	velocity = Vector2(randf_range(-4.0, 4.0), randf_range(-15.0, -20.0))
	rotation = velocity.x / 10

func _process(delta):
	position += velocity
	velocity.y += gravity
	if velocity.y > 0:
		rotation *= 1.1
