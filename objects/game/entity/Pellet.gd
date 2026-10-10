extends Area2D

func _on_body_entered(body):
	if body.is_in_group('players'):
		# Optimistic local munch (sound + visual); the host authorizes the
		# stat and broadcasts, so every screen converges on eaten pellets.
		Global.incrementStat(body.playerId, Global.StatEnum.PELLETS, 1)
		if Net.isOnline and multiplayer.is_server():
			Net.pellet_eaten.rpc(global_position)
		$Polygon2D.hide()
		$AudioPickup.play()
		await $AudioPickup.finished
		if is_queued_for_deletion():
			return
		queue_free()
