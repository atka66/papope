extends Area2D

@export var originPlayerId: int = 0
@export var armed: bool = false

func _ready():
	$AudioSprung.stream = Res.AudioWhipHuts.pick_random()

func _on_body_entered(body):
	if armed:
		if body.is_in_group('trappables'):
			body.getTrapped()
			$Anim.play("spring")
