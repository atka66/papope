extends Area2D

func _on_Pellet_body_entered(body):
	if body.is_in_group('players'):
		Global.incrementStat(body.playerId, Global.StatEnum.PELLETS, 1)
		queue_free()
