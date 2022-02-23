extends Node2D

func _ready():
	$Phase1.hide()
	$Phase2.hide()
	$ParticlesTop.emitting = false
	$ParticlesBottom.emitting = false
	$Phase2/CollisionShape2D.disabled = true
	var loop = _rayLoop()

func _rayLoop():
	yield(get_tree().create_timer(18.0), "timeout")
	$Phase1.show()
	$Phase1/Phase1Anim.play()
	$AudioStart.play()
	yield(get_tree().create_timer(0.8), "timeout")
	$Phase1.hide()
	$Phase2.show()
	$ParticlesTop.emitting = true
	$ParticlesBottom.emitting = true
	$AudioOngoing.play()
	$Phase2/CollisionShape2D.disabled = false
	yield(get_tree().create_timer(4.2), "timeout")
	$AudioOngoing.stop()
	$AudioStop.play()
	$Phase2.hide()
	$ParticlesTop.emitting = false
	$ParticlesBottom.emitting = false
	$Phase2/CollisionShape2D.disabled = true
	var rerun = _rayLoop()

func _on_Phase2_body_entered(body):
	if body.is_in_group('players'):
		$AudioCollisionPlayer.play()
		body.hurt(Global.DAMAGE_SPACERAY)
		if body.wasJustKilled(body):
			body.die(Global.DeathEnum.LASER)
		var vector = Vector2(-body.linear_velocity.x, 0)
		
		var vel = Vector2(1, 0)
		if body.global_position.x < 340:
			vel.x *= -1
		body.apply_central_impulse(vector + (vel * 800))
	if body.is_in_group('dynamites'):
		body.explode()

func _process(delta):
	if $Phase2.visible:
		Global.shakeScreen(3)
