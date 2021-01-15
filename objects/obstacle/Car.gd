extends Area2D

var fromRight = false
var speed = 0

func _ready():
	$Sprite.frame = randi() % $Sprite.vframes
	$Sprite.flip_h = !fromRight

func _process(delta):
	if fromRight:
		if position.x < -200:
			queue_free()
		position.x -= speed
	else:
		if position.x > 880:
			queue_free()
		position.x += speed


func _on_Car_body_entered(body):
	if body.is_in_group('players'):
		$AudioCollision.stream = Res.AudioCollisionCar[randi() % len(Res.AudioCollisionCar)]
		$AudioCollision.play()
		body.hurt(Global.DAMAGE_CAR)
		var vector = -body.linear_velocity
		
		var vel = Vector2(1, 1)
		if fromRight:
			vel.x *= -1
		if global_position.y > body.global_position.y:
			vel.y *= -1
		
		body.apply_central_impulse(vector + (vel * 600))
	if body.is_in_group('dynamites'):
		body.explode()
