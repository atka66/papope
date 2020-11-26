extends RigidBody2D

export var originPlayerId = 0

func _ready():
	$Sprite.rotation_degrees = randi() % 360
	yield(get_tree().create_timer(1.0), "timeout")
	explode()

func _process(delta):
	$Sprite.rotation_degrees += 10

func explode():
	var fullDmg = 0
	for player in get_tree().get_nodes_in_group('players'):
		var dist = position.distance_to(player.position)
		if dist < 150:
			var power = 150 - dist;
			player.apply_central_impulse(position.direction_to(player.position) * power * 20)
			var dmg = power / 1.5
			if player.wouldRighteouslyBeHitBy(originPlayerId):
				fullDmg += dmg
			player.hurt(dmg)
	Global.incrementStat(originPlayerId, Global.Stat.DYN_DMG, fullDmg)
	var explosionAnim = Global.ExplosionAnim.instance()
	explosionAnim.position = position
	get_tree().get_root().add_child(explosionAnim)
	queue_free()

func _on_Dynamite_body_entered(body):
	if body.is_in_group('players') && body.playerId != originPlayerId:
		explode()
