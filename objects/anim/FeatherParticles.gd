extends CPUParticles2D

func _ready():
	if Global.MapControllerNode.isDisco:
		$FeatherParticles.modulate = Color.BLACK

func _on_finished():
	queue_free()
