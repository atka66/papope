extends Node2D

export(int) var shakePwr = 0
var originPlayerId

func _ready():
	Global.shakeScreen(shakePwr)
	$BigBoom.emitting = true
	$Smoke.emitting = true
	$Shards.emitting = true
	var fullDmg = 0
	for player in get_tree().get_nodes_in_group('players'):
		var dist = position.distance_to(player.position)
		if dist < 150:
			var power = 150 - dist;
			player.apply_central_impulse(position.direction_to(player.position) * power * 10)
			var dmg = power / 1.5
			if player.wouldRighteouslyBeHitBy(originPlayerId):
				fullDmg += dmg
			player.hurt(dmg)
			if player.playerId != originPlayerId && Global.playersPerks[originPlayerId].has(Global.PerkEnum.VAMPIRE):
				Global.getPlayerNode(originPlayerId).heal(dmg)
			if player.wasJustKilled(player):
				player.die(Global.DeathEnum.EXPLOSION)
				if !player.isTeammate(originPlayerId):
					Global.addKill(originPlayerId)
	Global.incrementStat(originPlayerId, Global.StatEnum.DYN_DMG, fullDmg)
	for destructible in get_tree().get_nodes_in_group('destructible'):
		var dist = position.distance_to(destructible.position)
		if dist < 150:
			destructible.destroy(position.direction_to(destructible.position) * 30)
	for particle in get_tree().get_nodes_in_group('destructionparticle'):
		var dist = position.distance_to(particle.position)
		if dist < 150:
			particle.impulse(position.direction_to(particle.position) * 150)
	for cactus in get_tree().get_nodes_in_group('cacti'):
		var dist = position.distance_to(cactus.position)
		if dist < 150:
			cactus.get_node('Anim').play('hit')
	$Audio.stream = Res.AudioExplode[randi() % len(Res.AudioExplode)]
	$Audio.play()

func _process(delta):
	if !$BigBoom.emitting && !$Smoke.emitting && !$Shards.emitting:
		queue_free()
