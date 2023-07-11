extends Area2D

@export var originPlayerId: int = 0
@export var armed: bool = false

func _on_body_entered(body):
	if armed:
		if body.is_in_group('trappables'):
			# todo dmg
			body.getTrapped(originPlayerId)
			$Anim.play("spring")
			var crack = Res.CrackAnimObject.instantiate()
			crack.position = position
			Global.addToScene(crack)
