extends Node2D

var velocity = Vector2.ZERO
var gravity = 1

func _ready():
	velocity = Vector2(randf_range(-2.0, 2.0), randf_range(-7.0, -10.0))
	rotation = velocity.x / 10

func _process(delta):
	position += velocity
	velocity.y += gravity
	if velocity.y > 0:
		rotation *= 1.2
