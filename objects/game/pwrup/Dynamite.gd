extends RigidBody2D

@export var origin: Node2D
@export var originPlayerId: int = 0

func _ready():
	add_collision_exception_with(origin)

func explode():
	var explosion = Res.ExplosionAnimObject.instantiate()
	explosion.position = position
	explosion.originPlayerId = originPlayerId
	explosion.shakePwr = 15
	get_tree().get_current_scene().add_child(explosion)
	queue_free()

func getShot(playerId: int, normal: Vector2) -> void:
	explode()

func getTrapped():
	explode()
