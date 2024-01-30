extends Area2D

@export var fromRight: bool = false
@export var speed: float = 10.0

func _ready():
	$AudioHorn.stream = Res.AudioCarHorn.pick_random()
	$Sprite.frame = randi() % $Sprite.vframes
	$Sprite.flip_h = !fromRight

func _process(delta):
	if fromRight:
		if position.x < -2000:
			queue_free()
		position.x -= speed
	else:
		if position.x > 3560:
			queue_free()
		position.x += speed

func _on_body_entered(body):
	if body.is_in_group('players'):
		$AudioCollision.stream = Res.AudioContactCar.pick_random()
		$AudioCollision.play()
		body.hurt(Global.DAMAGE_CAR, null)
		var vector = -body.linear_velocity
		var vel = Vector2(1, randf_range(0.5, 1.0))
		if fromRight:
			vel.x *= -1
		if global_position.y > body.global_position.y:
			vel.y *= -1
		body.apply_central_impulse(vector + (vel * 1200))
		if !$AudioHorn.playing:
			$AudioHorn.play()
	if body.is_in_group('dynamites'):
		body.explode()
		$AudioCollision.stream = Res.AudioContactCar.pick_random()
		$AudioCollision.play()

func getShot(playerId: int, normal: Vector2) -> void:
	$AudioCollision.stream = Res.AudioContactCar.pick_random()
	$AudioCollision.play()

func getWhipped(playerId: int, normal: Vector2) -> void:
	$AudioCollision.stream = Res.AudioContactCar.pick_random()
	$AudioCollision.play()
