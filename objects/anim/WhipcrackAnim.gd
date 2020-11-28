extends AnimatedSprite

func _ready():
	$Audio.stream = Res.AudioWhipHuts[randi() % len(Res.AudioWhipHuts)]
	$Audio.play()
	play()

func _on_WhipcrackAnim_animation_finished():
	hide()
	yield($Audio, "finished")
	queue_free()
