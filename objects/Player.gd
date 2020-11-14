extends RigidBody2D

export var playerId = 0

var inLobby = false
var hit = false
var alive = true
var hp = Global.options['hp'][Global.optionsSelected['hp']]
var contactedLava = false
var item = null
var ammo = 0
var hurtByLava = false
var outsideCntdwn = 3
var invulnerable = false
var fallWater = false
var trapped = false
var hurtIntensity = 0.0

var thrust = Vector2.ZERO
var speed = 40
var frictionCustom = 0.2

var inputCd = false

func _ready():
	$Crosshair.hide()
	$WhiplashAnim.hide()
	inLobby = get_tree().get_current_scene().get_name() == 'Lobby'
	if !inLobby:
		get_tree().get_current_scene().get_node('Hud' + str(playerId)).player = self
	$Body.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Face.frame = Global.playersSkin[playerId]
	$SpawnAnim.play()

func _input(event):
	var lhAxis = Input.get_joy_axis(playerId, JOY_AXIS_0)
	var lvAxis = Input.get_joy_axis(playerId, JOY_AXIS_1)
	if abs(lhAxis) < 0.1 : lhAxis = 0.0
	if abs(lvAxis) < 0.1 : lvAxis = 0.0
	thrust = Vector2(lhAxis, lvAxis) * speed

	if alive:
		var aimVector = Vector2(
			Input.get_joy_axis(playerId, JOY_AXIS_2), 
			Input.get_joy_axis(playerId, JOY_AXIS_3)
		)
		# correct axis if pointing at origin
		if aimVector.x == 0.0 && aimVector.y == 0.0:
			aimVector.x = 0.001;
		$HitScan.cast_to = aimVector
		$Crosshair.rotation = aimVector.angle()
		$Crosshair.position = aimVector
		if item == 'revolver' || item == 'dynamite':
			$HitScan.cast_to = extendVectorTo(aimVector, 5000)
			$Crosshair.position *= 200
		if item == 'whip':
			$HitScan.cast_to = extendVectorTo(aimVector, 96)
			$Crosshair.position *= 96

	if event.device == playerId && !inputCd:
		inputCd = true
		if inLobby:
			if Input.is_action_just_pressed("pl_skin_next"):
				Global.playersSkin[playerId] = (Global.playersSkin[playerId] + 1) % Global.SKIN_COUNT
			if Input.is_action_just_pressed("pl_skin_prev"):
				Global.playersSkin[playerId] = (Global.playersSkin[playerId] + (Global.SKIN_COUNT - 1)) % Global.SKIN_COUNT
			if Input.is_action_just_pressed("pl_team_next"):
				Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 1) % 4
			if Input.is_action_just_pressed("pl_team_prev"):
				Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 3) % 4
			$Face.frame = Global.playersSkin[playerId]
			$Body.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]
		else:
			if alive && !Global.playersFrozen && !fallWater:
				if !trapped:
					if Input.is_action_just_pressed('pl_game_dash'):
						apply_central_impulse(thrust.normalized() * 750)
				if Input.is_action_just_pressed('pl_game_use'):
					useItem()

func _process(delta):
	inputCd = false
	if hp < 1:
		$Body.modulate = Global.TEAM_COLORS[4]
		alive = false
		hp = 0
		ammo = 0
		item = null
		$Crosshair.hide()

func _physics_process(delta):
	#friction
	apply_central_impulse(-linear_velocity * frictionCustom)
	apply_central_impulse(thrust)

func _on_remove(id):
	if playerId == id:
		queue_free()

func _on_SpawnAnim_animation_finished():
	$SpawnAnim.hide()

func _on_Player_body_entered(body):
	if body.get_name() == 'Player':
		if !hit:
			body.hit = true
			var collisionAnim = Global.CollisionAnim.instance()
			var animScale = (thrust.length() + body.thrust.length()) / 30
			collisionAnim.scale = Vector2(animScale, animScale)
			collisionAnim.play()
			collisionAnim.position = body.global_position - ((body.global_position - global_position) / 2)
			collisionAnim.look_at(body.global_position)
			get_tree().get_root().add_child(collisionAnim)
		apply_central_impulse(body.global_position.direction_to(global_position) * 100)
		hit = false

func extendVectorTo(vector, length):
	return vector * (length / vector.length())

func pickup(pwrup):
	spawnPickupLabel(pwrup)
	item = pwrup
	if pwrup == 'revolver':
		$Crosshair.show()
		$Crosshair.frame = 0
		ammo = 6
	if pwrup == 'dynamite':
		$Crosshair.show()
		$Crosshair.frame = 1
		ammo = 1
	if pwrup == 'shield':
		ammo = 1
	if pwrup == 'trap':
		ammo = 1
	if pwrup == 'whip':
		$Crosshair.show()
		$Crosshair.frame = 2
		ammo = 5

func spawnPickupLabel(text):
	var pickupLabel = Global.CustomLabel.instance()
	pickupLabel.position = Vector2(0, -32)
	pickupLabel.text = text
	pickupLabel.fontSize = 2
	pickupLabel.outline = false
	pickupLabel.aliveTime = 1
	pickupLabel.alignment = Label.ALIGN_CENTER
	add_child(pickupLabel)

func useItem():
		if item == 'revolver':
			if $HitScan.is_colliding():
				var collider = $HitScan.get_collider()
		if item == 'whip':
			var angle = $HitScan.cast_to.angle()
			$WhiplashAnim.rotation = angle
			$WhiplashAnim.frame = 0
			$WhiplashAnim.show()
			$WhiplashAnim.play()
			var whipcrackAnim = Global.WhipcrackAnim.instance()
			var crackPosition = global_position + $HitScan.cast_to
			if $HitScan.is_colliding():
				var collider = $HitScan.get_collider()
				if collider.is_in_group('players'):
					crackPosition = $HitScan.get_collision_point()
					collider.hurt(30)
					collider.apply_central_impulse($HitScan.cast_to.normalized() * 2500)
			whipcrackAnim.position = crackPosition
			get_tree().get_root().add_child(whipcrackAnim)
		if item != null:
			ammo -= 1
			if ammo < 1:
				item = null
				$Crosshair.hide()

func hurt(damage):
	if damage > 0 && alive && !invulnerable && !Global.playersFrozen:
		hp -= damage;
		#TODO hp removal particle
		#TODO shake hud
		hurtIntensity = 1.0;

func _on_WhiplashAnim_animation_finished():
	$WhiplashAnim.hide()
