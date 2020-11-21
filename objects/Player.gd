extends RigidBody2D

export var playerId = 0

var inLobby = false
var hit = false
var alive = true
var hp = Global.options['hp'][Global.optionsSelected['hp']]
var item = null
var ammo = 0
var contactsLava = false
var outsideCntdwn = 180
var invulnerable = false
var fallWater = false
var trapped = false
var inSpace = false

var thrust = Vector2.ZERO
var speed = 40
var frictionCustom = 0.2

var color = Global.TEAM_COLORS[0]
var inputCd = false

func _ready():
	$InvulAnim.play()
	$InvulAnim.hide()
	$Crosshair.hide()
	$WhiplashAnim.hide()
	$OutsideLabel.hide()
	$SmokeParticles.emitting = false
	inLobby = get_tree().get_current_scene().get_name() == 'Lobby'
	if !inLobby:
		var hud = Global.Hud.instance()
		var position = Vector2.ZERO
		if playerId == 0: position = Vector2(-120, 4)
		if playerId == 1: position = Vector2(688, 4)
		if playerId == 2: position = Vector2(-120, 340)
		if playerId == 3: position = Vector2(688, 340)
		hud.name = 'Hud' + str(playerId)
		hud.position = position
		hud.player = self
		hud.fromRight = (playerId % 2 == 1)
		get_parent().add_child(hud)
	color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Body.modulate = color
	$Crosshair.modulate = color
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
		if item == 'revolver':
			$HitScan.cast_to = extendVectorTo(aimVector, 5000)
			$Crosshair.position *= 200
		if item == 'dynamite':
			$Crosshair.position *= 200
		if item == 'whip':
			$HitScan.cast_to = extendVectorTo(aimVector, 96)
			$Crosshair.position *= 96

	if event.device == playerId && !inputCd:
		inputCd = true
		if inLobby:
			if !Global.Lobby.countingDown:
				if Input.is_action_just_pressed("pl_skin_next"):
					Global.playersSkin[playerId] = (Global.playersSkin[playerId] + 1) % Global.SKIN_COUNT
				if Input.is_action_just_pressed("pl_game_use"):
					Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 1) % 4
				if Input.is_action_just_pressed("pl_game_dash"):
					Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 3) % 4
				$Face.frame = Global.playersSkin[playerId]
				$Body.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]
		else:
			if alive && !Global.playersFrozen && !fallWater:
				if !trapped && linear_velocity.length() < 1000:
					if Input.is_action_just_pressed('pl_game_dash'):
						apply_central_impulse(linear_velocity.normalized() * 750)
				if Input.is_action_just_pressed('pl_game_use'):
					useItem()

func _process(delta):
	inputCd = false
	if !inLobby:
		if alive:
			if contactsLava:
				hurt(1)
			if outsideCntdwn < 1:
				hp = 0
			if hp < 1:
				$Body.modulate = Global.TEAM_COLORS[4]
				alive = false
				hp = 0
				ammo = 0
				item = null
				$Crosshair.hide()

				if !Global.playersFrozen:
					var aliveTeamId = Global.getWinnerTeam();
					if aliveTeamId != -1: # round is over
						get_tree().get_nodes_in_group('controllers')[0].endRound(aliveTeamId)
			
			if !Global.playersFrozen && !fallWater:
				if isOutside():
					if outsideCntdwn > 0:
						updateOutsideLabel()
						$OutsideLabel.show()
						outsideCntdwn -= 1
				else:
					$OutsideLabel.hide()
					outsideCntdwn = 180
		else:
			$OutsideLabel.hide()

func updateOutsideLabel():
	$OutsideLabel.global_position = Vector2(
		max(min(global_position.x, 648), 32),
		max(min(global_position.y, 349), 29)
	)
	$OutsideLabel.set_text(str(ceil(float(outsideCntdwn) / 60)))
	if (outsideCntdwn / 10) % 2:
		$OutsideLabel.set_color(Color.white)
	else:
		$OutsideLabel.set_color(color)

func _physics_process(delta):
	#friction
	if !fallWater && !inSpace:
		apply_central_impulse(-linear_velocity * frictionCustom)
		if alive && !Global.playersFrozen && !trapped:
			apply_central_impulse(thrust)

func _on_remove(id):
	if playerId == id:
		queue_free()

func _on_SpawnAnim_animation_finished():
	$SpawnAnim.hide()

func _on_Player_body_entered(body):
	if body.is_in_group('players'):
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
	if body.is_in_group('cacti'):
		hurt(10)
		apply_central_impulse(body.global_position.direction_to(global_position) * 200)

func extendVectorTo(vector, length):
	return vector * (float(length) / vector.length())

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
		$Crosshair.hide()
		ammo = 1
	if pwrup == 'trap':
		$Crosshair.hide()
		ammo = 1
	if pwrup == 'whip':
		$Crosshair.show()
		$Crosshair.frame = 2
		ammo = 5

func trap():
	hurt(35)
	trapped = true
	yield(get_tree().create_timer(2.0), "timeout")
	trapped = false

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
			var revolverRay = Global.RevolverRay.instance()
			var hitPosition = global_position + $HitScan.cast_to
			if $HitScan.is_colliding():
				var collider = $HitScan.get_collider()
				hitPosition = $HitScan.get_collision_point()
				if collider.is_in_group('players'):
					collider.hurt(20)
					collider.apply_central_impulse($HitScan.cast_to.normalized() * 200)
			revolverRay.position = position
			revolverRay.rotation = $HitScan.cast_to.angle()
			revolverRay.length = (position - hitPosition).length()
			get_tree().get_root().add_child(revolverRay)
		if item == 'dynamite':
			var dynamite = Global.Dynamite.instance()
			dynamite.position = position + ($HitScan.cast_to.normalized()) * 16
			dynamite.originPlayerId = playerId
			dynamite.apply_central_impulse($HitScan.cast_to * 190)
			get_tree().get_root().add_child(dynamite)
		if item == 'shield':
			invulnerable = true
			$InvulAnim.show()
			$InvulAnim/Timer.start(5)
		if item == 'trap':
			var trap = Global.Trap.instance()
			trap.rotation_degrees += (randi() % 60) - 30
			trap.position = position
			get_tree().get_root().add_child(trap)
		if item == 'whip':
			var angle = $HitScan.cast_to.angle()
			$WhiplashAnim.rotation = angle
			$WhiplashAnim.frame = 0
			$WhiplashAnim.show()
			$WhiplashAnim.play()
			var whipcrackAnim = Global.WhipcrackAnim.instance()
			var hitPosition = global_position + $HitScan.cast_to
			if $HitScan.is_colliding():
				var collider = $HitScan.get_collider()
				if collider.is_in_group('players'):
					hitPosition = $HitScan.get_collision_point()
					collider.hurt(30)
					collider.apply_central_impulse($HitScan.cast_to.normalized() * 2500)
			whipcrackAnim.position = hitPosition
			get_tree().get_root().add_child(whipcrackAnim)
		if item != null:
			ammo -= 1
			if ammo < 1:
				item = null
				$Crosshair.hide()

func _endInvul():
	invulnerable = false
	$InvulAnim.hide()

func hurt(damage):
	if damage > 0 && alive && !invulnerable && !Global.playersFrozen:
		hp -= damage;
		$Hurt/HurtAnim.stop()
		$Hurt/HurtAnim.play()
		#TODO hp removal particle

func _on_WhiplashAnim_animation_finished():
	$WhiplashAnim.hide()

func isOutside():
	return global_position.x < 0 || global_position.x > 680 || global_position.y < 0 || global_position.y > 384
		
