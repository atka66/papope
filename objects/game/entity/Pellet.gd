extends Area2D

func _on_body_entered(body):
	if body.is_in_group('players'):
		# Online pellets are host-authorized like pickups: guests neither
		# count nor munch locally, the broadcast below carries sight+sound.
		if Net.isOnline and not multiplayer.is_server():
			return
		Global.incrementStat(body.playerId, Global.StatEnum.PELLETS, 1)
		if Net.isOnline:
			Net.pellet_eaten.rpc(global_position)
		consume()

func consume() -> void:
	$Polygon2D.hide()
	$AudioPickup.play()
	await $AudioPickup.finished
	if is_queued_for_deletion():
		return
	queue_free()
