extends AnimatedSprite

func _ready():
	$Audio.stream = Res.AudioRevRicochet[randi() % len(Res.AudioRevRicochet)]
	$Audio.play()
	play()

func _on_SpawnAnim_animation_finished():
	hide()
	yield($Audio, "finished")
	queue_free()
