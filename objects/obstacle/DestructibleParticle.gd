extends RigidBody2D

func _ready():
	$Sprite.frame = randi() % $Sprite.hframes

func impulse(direction):
	var actualImpulse = Vector2(
		(direction.x + (randi() % 100) - 50) * (randi() % 10), 
		(direction.y + (randi() % 100) - 50) * (randi() % 10)
	)
	apply_central_impulse(actualImpulse)
	add_torque((randi() % 300) - 150)
