extends AudioStreamPlayer2D

func _ready():
	stream = Res.AudioRevRicochet[randi() % len(Res.AudioRevRicochet)]
	play()

func _on_Audio_finished():
	queue_free()
