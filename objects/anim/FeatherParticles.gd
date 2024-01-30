extends CPUParticles2D

func _ready():
	if Global.MapControllerNode.isDisco:
		modulate = Color.BLACK

func _on_finished():
	queue_free()
