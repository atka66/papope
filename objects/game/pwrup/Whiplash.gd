extends Node2D

var maxLength: int = 192
@export var origin: Node2D
@export var targetNorm: Vector2

func _ready():
	if Global.MapControllerNode.isNightclub:
		$Container/WhipSprite.modulate = Color.BLACK

	if Global.playersPerks[origin.playerId].has(Global.PerkEnum.LONG_ARMS):
		maxLength *= 2
		$Container/WhipSprite.scale *= 2
	
	$HitScan.add_exception(origin)
	$Container.rotate(targetNorm.angle())

	# Online the host owns the hit scan and the crack FX (Net.whip_fx): a guest
	# ray runs against 100ms-lagged bodies and picks the wrong player-hit flag.
	if Net.isOnline and not Net.isHost:
		return

	var hitPosition: Vector2
	$HitScan.target_position = Global.extendVectorTo(targetNorm, maxLength)
	$HitScan.force_raycast_update()
	var playerHit = false
	if $HitScan.is_colliding():
		hitPosition = $HitScan.get_collision_point()
		var collider = $HitScan.get_collider()
		if collider.is_in_group('discowalls') and collider.has_method('boop'):
			# Neon ring: lights up for the lash too (no damage).
			collider.boop()
		if collider.is_in_group('whippables'):
			# Host-authoritative damage; guest lashes are visuals only.
			# Cacti are damage-free, so their wobble replays on any peer and
			# the host re-broadcasts it for peers holding no lash.
			var cosmetic: bool = collider.is_in_group('cacti')
			if cosmetic or not Net.isOnline or Net.isHost:
				collider.getWhipped(origin.playerId, $HitScan.target_position.normalized())
			if cosmetic and Net.isOnline and Net.isHost:
				Net.cactus_hit(collider.global_position, false)
			if collider.is_in_group('players'):
				playerHit = true
	else:
		hitPosition = $HitScan.target_position + global_position
	var crack = Res.CrackAnimObject.instantiate()
	crack.position = hitPosition
	crack.playerHit = playerHit
	Global.addToScene(crack)
	if Net.isOnline:
		Net.whip_fx(hitPosition, playerHit)

func _process(delta):
	position = origin.position

func _on_animated_sprite_2d_animation_finished():
	queue_free()
