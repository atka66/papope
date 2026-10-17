extends RigidBody2D

@export var origin: Node2D
@export var targetNorm: Vector2
@export var throwForce: float

func _ready():
	if Global.MapControllerNode.isNightclub:
		$Container/Sprite.modulate = Color.BLACK
		$Container/Smoke.z_as_relative = false
		$Container/Smoke.z_index = 5
	add_collision_exception_with(origin)
	apply_central_impulse(targetNorm * throwForce)

func explode():
	# Host-authoritative: only the host spawns the damaging blast and tells
	# guests to mirror it; guest copies are inert.
	if Net.isOnline and not Net.isHost:
		return
	var explosion = Res.ExplosionAnimObject.instantiate()
	explosion.position = position
	explosion.originPlayerId = origin.playerId
	explosion.shakePwr = 15
	Global.addToScene(explosion)
	if Net.isOnline:
		Net.dynamite_blast(position, origin.playerId)
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
		if Net.isOnline and not Net.isHost:
			return
		if body.alive && !body.shielded:
			body.directExplosion()
		explode()
	else:
		if body.is_in_group('discowalls') and body.has_method('boop'):
			body.boop()
		$AudioBounce.play()
