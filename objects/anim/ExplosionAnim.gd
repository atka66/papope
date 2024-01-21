extends Node2D

@export var harmful: bool = true
@export var shakePwr: int = 0
@export var originPlayerId: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.shakeScreen(shakePwr)
	$Smoke.restart()
	$BigBoom.restart()
	$Shards.restart()
	$Audio.stream = Res.AudioExplosion.pick_random()
	$Audio.play()
	
	if harmful:
		var accountableDmg = 0
		for player in get_tree().get_nodes_in_group('players'):
			var dist: float = position.distance_to(player.position)
			if dist < 300.0:
				var power: float = 300.0 - dist
				player.apply_central_impulse(position.direction_to(player.position) * power * 10)
				var dmg: float = power / 3.0
				if player.isRighteouslyHitBy(originPlayerId):
					accountableDmg += dmg
				player.hurt(dmg, originPlayerId)
		Global.incrementStat(originPlayerId, Global.StatEnum.DYN_DMG, accountableDmg)

func _process(delta):
	if !$BigBoom.emitting && !$Smoke.emitting && !$Shards.emitting:
		queue_free()
