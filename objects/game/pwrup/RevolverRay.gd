extends Node2D

const MAX_LENGTH: int = 5000
@export var origin: Node2D
@export var targetNorm: Vector2

func _ready():
	$HitScan.add_exception(origin)
	$Ray.add_point(targetNorm * 14)
	$MuzzleTop.rotate(targetNorm.angle())
	$MuzzleBottom.rotate(targetNorm.angle())
	
	var hitPosition: Vector2
	$HitScan.target_position = Global.extendVectorTo(targetNorm, MAX_LENGTH)
	$HitScan.force_raycast_update()
	if $HitScan.is_colliding():
		hitPosition = $HitScan.get_collision_point()
		var collider = $HitScan.get_collider()
		if collider.is_in_group('shootables'):
			collider.getShot(origin.playerId, $HitScan.target_position.normalized())
		else:
			var ricochet = Res.RevolverRicochetObject.instantiate()
			ricochet.position = hitPosition
			ricochet.rotation = $HitScan.target_position.bounce($HitScan.get_collision_normal()).angle()
			get_tree().get_current_scene().add_child(ricochet)
		# todo further coll detection
	else:
		hitPosition = $HitScan.target_position
	$Ray.add_point(hitPosition - global_position)

	await $Audio.finished
	queue_free()
