extends Area2D

export(bool) var wrapToLeft = false

func _on_Wrapper_body_entered(body):
	if body.is_in_group('players') || body.is_in_group('dynamites') || body.is_in_group('destructionparticle'):
		if wrapToLeft:
			body.wrapPosition = Vector2(-16, body.position.y)
		else:
			body.wrapPosition = Vector2(696, body.position.y)
