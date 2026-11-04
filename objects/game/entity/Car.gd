extends Area2D

@export var fromRight: bool = false
@export var speed: float = 600.0
@export var netPaint: int = -1 # online: host-rolled paint, -1 = roll locally
var laneName: String = "" # set by TrafficLane: host keys car FX replays by lane

func _ready():
	$AudioHorn.stream = Res.AudioCarHorn.pick_random()
	if netPaint >= 0:
		$Sprite.frame = absi(netPaint) % $Sprite.vframes
	else:
		$Sprite.frame = randi() % $Sprite.vframes
	$Sprite.flip_h = !fromRight

func playHitSound(horn: bool) -> void:
	$AudioCollision.stream = Res.AudioContactCar.pick_random()
	$AudioCollision.play()
	if horn and !$AudioHorn.playing:
		$AudioHorn.play()

func _process(delta):
	var deltaSpeed = delta * speed
	if fromRight:
		if position.x < -2000:
			queue_free()
		position.x -= deltaSpeed
	else:
		if position.x > 3560:
			queue_free()
		position.x += deltaSpeed

func _on_body_entered(body):
	if body.is_in_group('players'):
		# Car hits are host-authorized; guests converge hp/velocity via
		# state sync and replay the impact sound via Net.car_fx.
		if Net.isOnline and not Net.isHost:
			return
		playHitSound(true)
		if Net.isOnline:
			Net.car_fx(laneName, true)
		body.hurt(Global.DAMAGE_CAR, null)
		var vector = -body.linear_velocity
		var vel = Vector2(1, randf_range(0.5, 1.0))
		if fromRight:
			vel.x *= -1
		if global_position.y > body.global_position.y:
			vel.y *= -1
		body.apply_central_impulse(vector + (vel * 1200))
	if body.is_in_group('dynamites'):
		# Detonation is host-authorized (see Dynamite.explode); a guest car
		# must not set off its local dynamite copy.
		if Net.isOnline and not Net.isHost:
			return
		body.explode()
		playHitSound(false)
		if Net.isOnline:
			Net.car_fx(laneName, false)

func getShot(playerId: int, normal: Vector2) -> void:
	playHitSound(false)
	if Net.isOnline:
		Net.car_fx(laneName, false)

func getWhipped(playerId: int, normal: Vector2) -> void:
	playHitSound(false)
	if Net.isOnline:
		Net.car_fx(laneName, false)
