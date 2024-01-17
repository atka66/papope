extends Node2D

var maxLength: int = 192
@export var origin: Node2D
@export var targetNorm: Vector2

func _ready():
	if Global.playersPerks[origin.playerId].has(Global.PerkEnum.LONG_ARMS):
		maxLength *= 2
		$Container/WhipSprite.scale *= 2
	
	$HitScan.add_exception(origin)
	$Container.rotate(targetNorm.angle())
	
	var hitPosition: Vector2
	$HitScan.target_position = Global.extendVectorTo(targetNorm, maxLength)
	$HitScan.force_raycast_update()
	if $HitScan.is_colliding():
		hitPosition = $HitScan.get_collision_point()
		var collider = $HitScan.get_collider()
		if collider.is_in_group('whippables'):
			collider.getWhipped(origin.playerId, $HitScan.target_position.normalized())
	else:
		hitPosition = $HitScan.target_position + global_position
	var crack = Res.CrackAnimObject.instantiate()
	crack.position = hitPosition
	Global.addToScene(crack)

func _process(delta):
	position = origin.position

func _on_animated_sprite_2d_animation_finished():
	queue_free()
