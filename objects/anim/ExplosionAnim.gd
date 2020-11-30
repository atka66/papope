extends AnimatedSprite

func _ready():
	$Audio.play()
	play()

func _on_AnimatedSprite_animation_finished():
	hide()
	yield($Audio, "finished")
	queue_free()
