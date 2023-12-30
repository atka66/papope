extends Area2D

@export var originPlayerId: int = 0
@export var armed: bool = false

func spring(entity: Node2D) -> void:
	if armed:
		if entity.is_in_group('trappables'):
			# todo dmg
			entity.getTrapped(originPlayerId)
			$Anim.play("spring")
			var crack = Res.CrackAnimObject.instantiate()
			crack.position = position
			Global.addToScene(crack)

func _on_body_entered(body):
	spring(body)

func _on_area_entered(area):
	spring(area)
