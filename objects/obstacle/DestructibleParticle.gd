tool
extends RigidBody2D

export(Texture) var sprite
var torque = 0

func _ready():
	$Sprite.texture = sprite
	$Sprite.frame = randi() % $Sprite.hframes

func impulse(direction):
	var actualImpulse = Vector2(
		(direction.x + (randi() % 100) - 50) * (randi() % 10), 
		(direction.y + (randi() % 100) - 50) * (randi() % 10)
	)
	apply_central_impulse(actualImpulse)
	torque = randf()

func _process(delta):
	if torque > 0:
		$Sprite.rotate(torque)
		torque -= 0.01
