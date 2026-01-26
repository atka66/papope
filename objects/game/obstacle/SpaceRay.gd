extends Node2D

func _process(delta):
	if $Phase2.visible:
		Global.shakeScreen(5)
		$Phase2/PointLight2D.energy = randf_range(0.5, 1.0)

func _on_phase_2_body_entered(body):
	if body.is_in_group('zappables'):
		$AudioHit.play() # todo other sound?
		body.getZapped()
