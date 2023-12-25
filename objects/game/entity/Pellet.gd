extends Area2D

func _on_body_entered(body):
	if body.is_in_group('players'):
		$Polygon2D.hide()
		$AudioPickup.play()
		await $AudioPickup.finished
		queue_free()
