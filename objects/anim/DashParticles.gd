extends CPUParticles2D

func _ready():
	if Global.MapControllerNode.isDisco:
		$DashParticles.modulate = Color.BLACK

func _on_finished():
	queue_free()
