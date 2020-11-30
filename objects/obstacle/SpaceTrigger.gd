extends Area2D

func _on_SpaceTrigger_body_entered(body):
	if body.is_in_group('players'):
		body.inSpace = true

func _on_SpaceTrigger_body_exited(body):
	if body.is_in_group('players'):
		body.inSpace = false
