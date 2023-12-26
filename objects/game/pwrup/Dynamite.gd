extends RigidBody2D

@export var origin: Node2D
@export var targetNorm: Vector2
@export var throwForce: float

func _ready():
	add_collision_exception_with(origin)
	apply_central_impulse(targetNorm * throwForce)

func explode():
	var explosion = Res.ExplosionAnimObject.instantiate()
	explosion.position = position
	explosion.originPlayerId = origin.playerId
	explosion.shakePwr = 15
	Global.addToScene(explosion)
	queue_free()

func getShot(playerId: int, normal: Vector2) -> void:
	explode()

func getTrapped(playerId: int) -> void:
	explode()

func getWhipped(playerId: int, normal: Vector2) -> void:
	explode()

func getZapped() -> void:
	explode()

func _integrate_forces(state):
	Global.pacmanWrap(state)

func _on_body_entered(body):
	if body.is_in_group("players"):
		if body.alive && !body.shielded:
			body.directExplosion()
		explode()
	else:
		$AudioBounce.play()
