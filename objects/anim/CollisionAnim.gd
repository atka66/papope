extends AnimatedSprite

func _ready():
	$Audio.stream = Res.AudioCollisionPlayer[randi() % len(Res.AudioCollisionPlayer)]
	$Audio.play()
	play()

func _on_CollisionAnim_animation_finished():
	hide()
	yield($Audio, "finished")
	queue_free()
