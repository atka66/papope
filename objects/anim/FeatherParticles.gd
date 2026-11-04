extends CPUParticles2D

func _ready():
	if Global.inNightclub():
		modulate = Color.BLACK

func _on_finished():
	queue_free()
