extends Node2D

const MAX_LENGTH: int = 5000
@export var origin: Node2D
@export var targetNorm: Vector2

func _ready():
	$HitScan.add_exception(origin)

	var originPoint: Vector2 = targetNorm * 14
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
		if collider.is_in_group('shootables'):
			collider.getShot(origin.playerId, $HitScan.target_position.normalized())
			if collider.is_in_group('car'):
				spawnRicochet(hitPosition, hitAngle)
		else:
			spawnRicochet(hitPosition, hitAngle)
		# todo further coll detection
	else:
		hitPosition = $HitScan.target_position
	$Ray.add_point(hitPosition - global_position)

	await $Audio.finished
	queue_free()

func spawnRicochet(position: Vector2, angle: float) -> void:
	var ricochet = Res.RevolverRicochetAnimObject.instantiate()
	ricochet.position = position
	ricochet.rotation = angle
	Global.addToScene(ricochet)
