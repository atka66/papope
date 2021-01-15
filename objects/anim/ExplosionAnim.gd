extends AnimatedSprite

var originPlayerId

func _ready():
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
			if player.wasJustKilled(player) && !player.isTeammate(originPlayerId):
				Global.addKill(originPlayerId)
	Global.incrementStat(originPlayerId, Global.StatEnum.DYN_DMG, fullDmg)
	$Audio.play()
	play()

func _on_AnimatedSprite_animation_finished():
	hide()
	yield($Audio, "finished")
	queue_free()
