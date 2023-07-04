extends RigidBody2D

@export var originPlayerId: int = 0

func _ready():
	pass # Replace with function body.

func explode():
	var explosion = Res.ExplosionAnimObject.instantiate()
	explosion.position = position
	explosion.originPlayerId = originPlayerId
	explosion.shakePwr = 15
	get_tree().get_current_scene().add_child(explosion)
	queue_free()
