extends Node2D

const MAX_LENGTH: int = 5000
@export var origin: Node2D
@export var targetNorm: Vector2

func _ready():
	if Global.MapControllerNode.isNightclub:
		z_as_relative = false
		z_index = 5

	$HitScan.add_exception(origin)

	var originPoint: Vector2 = targetNorm * 28
	$Ray.add_point(originPoint)
	$MuzzleTop.position = originPoint
	$MuzzleTop.rotate(targetNorm.angle())
	$MuzzleBottom.position = originPoint
	$MuzzleBottom.rotate(targetNorm.angle())
	
	var hitPosition: Vector2
	$HitScan.target_position = Global.extendVectorTo(targetNorm, MAX_LENGTH)
	$HitScan.force_raycast_update()
	if $HitScan.is_colliding():
		hitPosition = $HitScan.get_collision_point()
		var hitAngle = $HitScan.target_position.bounce($HitScan.get_collision_normal()).angle()
		var collider = $HitScan.get_collider()
		if collider.is_in_group('discowalls') and collider.has_method('boop'):
			# Neon ring: lights up for whatever it stopped (no damage).
			collider.boop()
		if collider.is_in_group('shootables'):
			# Damage is host-authoritative; guest rays are visuals only while
			# hp/kills converge via state sync (same rule as Trap/Pwrup).
			# Cacti take no damage, so their wobble is safe to replay on any
			# peer and the host re-broadcasts it for peers holding no ray.
			var cosmetic: bool = collider.is_in_group('cacti')
			if cosmetic or not Net.isOnline or Net.isHost:
				collider.getShot(origin.playerId, $HitScan.target_position.normalized())
			if cosmetic and Net.isOnline and Net.isHost:
				Net.cactus_hit(collider.global_position, false)
			if collider.is_in_group('players'):
				$AudioPlayerHit.play()
			if collider.is_in_group('car'):
				spawnRicochet(hitPosition, hitAngle)
		else:
			spawnRicochet(hitPosition, hitAngle)
		$Ray.add_point(hitPosition - global_position)
	else:
		$Ray.add_point($HitScan.target_position)

	await $Audio.finished
	queue_free()

func spawnRicochet(position: Vector2, angle: float) -> void:
	var ricochet = Res.RevolverRicochetAnimObject.instantiate()
	ricochet.position = position
	ricochet.rotation = angle
	Global.addToScene(ricochet)
