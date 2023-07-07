extends Node2D

func _process(delta):
	if $Phase2.visible:
		Global.shakeScreen(5)


func _on_phase_2_body_entered(body):
	if body.is_in_group('zappables'):
		$AudioHit.play() # todo other sound?
		body.getZapped()
