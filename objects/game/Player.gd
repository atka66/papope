extends RigidBody2D

@export var playerId: int = 0
var hud: Node

var silent: bool = false
var alive: bool = true
var deathReason: Global.DeathEnum = Global.DeathEnum.DEFAULT
var hp: int = 1
var item = null
var ammo: int = 0
var contactsLava: bool = false
var outsideCd: int = Global.OUTSIDE_CD
var timebombCd: int = Global.TIMEBOMB_CD
var shielded: bool = false
var trapped: bool = false
var fallWater: bool = false
var inSpace: bool = false
var hit: bool = false

var thrust: Vector2 = Vector2.ZERO
var speed: int = 20
var dashMultiplier: int = 30
var frictionCustom: float = 0.1

var inputCd: bool = false

func _ready():
	hp = Global.playersMaxHp[playerId]
	Global.playersKills[playerId] = 0
	
	$Shield.hide()
	if !Global.playersCrowned[playerId]:
		$Crown.hide()
	$Lock.hide()
	hideCrosshairs()
	
	updateColor(Global.TEAM_COLORS[Global.playersTeam[playerId]])
	
	if !silent:
		var anim = Res.SpawnPlayerAnimObject.instantiate()
		anim.position = global_position
		Global.addToScene(anim)
	
	if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		$BodyParts/Face.frame = 6
	else:
		$BodyParts/Face.frame = Global.playersSkin[playerId]

func _input(event):
	var lhAxis: float = Input.get_joy_axis(playerId, JOY_AXIS_LEFT_X)
	var lvAxis: float = Input.get_joy_axis(playerId, JOY_AXIS_LEFT_Y)
	if abs(lhAxis) < 0.1:
		lhAxis = 0.0
	if abs(lvAxis) < 0.1:
		lvAxis = 0.0

	var lAxis: Vector2 = Vector2(lhAxis, lvAxis)

	# todo no legs + reverse
	thrust = lAxis * speed

	if alive:
		var rAxis: Vector2 = Vector2(
			Input.get_joy_axis(playerId, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(playerId, JOY_AXIS_RIGHT_Y)
		)
		
		if rAxis.x == 0.0 && rAxis.y == 0.0:
			rAxis.x = 0.001
		
		# todo perks: backfire + right
		
		$LookVector.position = rAxis
		$Crosshairs.rotation = rAxis.angle()
		$Crosshairs.position = rAxis
		
		match item:
			Global.PwrupEnum.REVOLVER:
				$Crosshairs.position *= 200
			Global.PwrupEnum.DYNAMITE:
				$Crosshairs.position *= 200
			Global.PwrupEnum.WHIP:
				$Crosshairs.position *= 96
				
		# todo perk long_arms

	if event.device == playerId && !inputCd:
		inputCd = true
		if Global.MapControllerNode == null:
			if event.is_action_pressed("skin_next"):
				Global.playersSkin[playerId] = (Global.playersSkin[playerId] + 1) % Global.SKIN_COUNT
				$BodyParts/Face.frame = Global.playersSkin[playerId]
			if ProjectSettings.get("papope/allow_players_set_options"):
					if event.is_action_pressed("game_use"):
						Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 1) % 4
					if event.is_action_pressed("game_dash"):
						Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 3) % 4
					updateColor(Global.TEAM_COLORS[Global.playersTeam[playerId]])
		else:
			if alive && !Global.playersFrozen && !fallWater:
				if !trapped && linear_velocity.length() < 1000:
					if event.is_action_pressed("game_dash"):
						dash(lAxis)
				if event.is_action_pressed("game_use"):
					useItem()

func updateColor(color: Color) -> void:
	var borderColor: Color = color.darkened(0.8)
	$BodyParts/Body.color = color
	$BodyParts.material.set_shader_parameter("border_color", borderColor)
	$Crosshairs.modulate = color
	$Crosshairs/DynamiteCrosshair.material.set_shader_parameter("line_color", borderColor)
	$Crosshairs/RevolverCrosshair.material.set_shader_parameter("line_color", borderColor)
	$Crosshairs/WhipCrosshair.material.set_shader_parameter("line_color", borderColor)
	if hud:
		hud.setHudColor(color)

func dash(axis: Vector2) -> void:
	$AudioDash.stream = Res.AudioPlayerDash.pick_random()
	$AudioDash.play()
	
	# todo chicken
	# todo no legs
	
	var impulse: Vector2 = linear_velocity.normalized() * speed * dashMultiplier
	apply_central_impulse(impulse)
	
	# todo dash animation

func _process(delta):
	inputCd = false
	if Global.MapControllerNode != null:
		if alive:
			if contactsLava && !shielded:
				hurt(Global.DAMAGE_LAVA)
			if outsideCd < 1:
				die(Global.DeathEnum.DEFAULT)
			if timebombCd < 1:
				die(Global.DeathEnum.EXPLOSION)
				var explosion = Res.ExplosionAnimObject.instantiate()
				explosion.position = position
				explosion.originPlayerId = playerId
				explosion.shakePwr = 15
				Global.addToScene(explosion)
			if hp < 1:
				updateColor(Global.TEAM_COLORS[4])
				alive = false
				# todo no chicken idle sound
				
				# todo falling message
				
				# todo register no refunds
				
				hp = 0
				ammo = 0
				hud.hideItems()
				item = null
				hideCrosshairs()
				# todo hide timebomb
				
				Global.shakeScreen(10)
				
				if !Global.playersFrozen:
					var aliveTeamId: int = Global.getWinnerTeam()
					if aliveTeamId != -1:
						Global.MapControllerNode.endRound(aliveTeamId)
						pass

			if !Global.playersFrozen and !fallWater:
				if Global.playersPerks[playerId].has(Global.PerkEnum.TIME_BOMB):
					# todo timebomb display
					timebombCd -= 1
				if isOutside():
					if outsideCd > 0:
						updateOutsideLabel()
						# todo show outside label
						outsideCd -= 1
				else:
					# todo hide outside label
					outsideCd = Global.OUTSIDE_CD
		else:
			# todo hide outside label
			pass

func isOutside() -> bool:
	return (
		global_position.x < Global.CameraNode.global_position.x 
		|| global_position.x > Global.CameraNode.global_position.x + 680 
		|| global_position.y < Global.CameraNode.global_position.y 
		|| global_position.y > Global.CameraNode.global_position.y + 384
	)

func updateOutsideLabel() -> void:
	# todo
	pass

func _physics_process(delta):
	if !inSpace:
		apply_central_impulse(-linear_velocity * frictionCustom)
		if alive && !Global.playersFrozen && !trapped:
			apply_central_impulse(thrust)

func _on_remove(id):
	if playerId == id:
		queue_free()

func pickup(pwrup : Global.PwrupEnum) -> void: 
	item = pwrup
	hideCrosshairs()
	match pwrup:
		Global.PwrupEnum.DYNAMITE:
			$Crosshairs/DynamiteCrosshair.show()
			ammo = 1
		Global.PwrupEnum.REVOLVER:
			$Crosshairs/RevolverCrosshair.show()
			ammo = 6
		Global.PwrupEnum.SHIELD:
			ammo = 1
		Global.PwrupEnum.TRAP:
			ammo = 1
		Global.PwrupEnum.WHIP:
			$Crosshairs/WhipCrosshair.show()
			ammo = 5
	hud.pickup(item, ammo)
	# todo akimbo perk 

func useItem() -> void:
	match item:
		Global.PwrupEnum.REVOLVER:
			Global.incrementStat(playerId, Global.StatEnum.REV_USE, 1)
			apply_central_impulse(-$LookVector.position.normalized() * 200)
			var revolverRay = Res.RevolverRayObject.instantiate()
			revolverRay.position = position
			revolverRay.origin = self
			revolverRay.targetNorm = $LookVector.position.normalized()
			Global.addToScene(revolverRay)
		Global.PwrupEnum.DYNAMITE:
			Global.incrementStat(playerId, Global.StatEnum.DYN_USE, 1)
			var dynamite = Res.DynamiteObject.instantiate()
			dynamite.position = position + ($LookVector.position.normalized()) * 20
			dynamite.origin = self
			dynamite.targetNorm = $LookVector.position.normalized()
			dynamite.throwForce = $LookVector.position.length() * 190
			Global.addToScene(dynamite)
		Global.PwrupEnum.SHIELD:
			shielded = true
			$Shield.show()
			$AudioShieldStart.play()
			$Shield/Timer.start(5.0)
		Global.PwrupEnum.TRAP:
			Global.incrementStat(playerId, Global.StatEnum.TRP_USE, 1)
			var trap = Res.TrapObject.instantiate()
			trap.position = position
			trap.rotation_degrees += (randi() % 30) - 60
			trap.originPlayerId = playerId
			Global.addToScene(trap)
		Global.PwrupEnum.WHIP:
			Global.incrementStat(playerId, Global.StatEnum.WHP_USE, 1)
			var whiplash = Res.WhiplashObject.instantiate()
			whiplash.position = position
			whiplash.origin = self
			whiplash.targetNorm = $LookVector.position.normalized()
			Global.addToScene(whiplash)

	if item != null:
			ammo -= 1
			hud.useItem(item, ammo)
			if ammo < 1:
				hud.hideItems()
				item = null
				hideCrosshairs()

func getShot(playerId: int, normal: Vector2) -> void:
	hurtSound(Res.AudioHurtRevolver)
	hurt(Global.DAMAGE_REVOLVER)
	#todo was just killed?
	apply_central_impulse(normal * 100)

func getTrapped(playerId: int) -> void:
	hurtSound(Res.AudioHurtTrap)
	hurt(Global.DAMAGE_TRAP)
	# todo was just killed?
	trapped = true
	$Lock.show()
	$Lock/Timer.start(2.0)

func getWhipped(playerId: int, normal: Vector2) -> void:
	hurtSound(Res.AudioHurtWhip)
	hurt(Global.DAMAGE_WHIP)
	# todo was just killed?
	apply_central_impulse(normal * 1000)

func getZapped() -> void:
	hurtSound(Res.AudioHurtCactus.pick_random()) #todo change?
	hurt(Global.DAMAGE_SPACERAY)
	#todo was just killed?
	
	var vector: Vector2 = Vector2(-linear_velocity.x, 0)
	var vel = Vector2.RIGHT
	if global_position.x < 336:
		vel.x *= -1
	apply_central_impulse(vector + (vel * 800))

func untrap():
	trapped = false
	$Lock.hide()

func directExplosion():
	hurtSound(Res.AudioHurtDynamite)

func unshield() -> void:
	shielded = false
	$Shield.hide()
	$AudioShieldEnd.play()

func hideCrosshairs() -> void:
	$Crosshairs/DynamiteCrosshair.hide()
	$Crosshairs/RevolverCrosshair.hide()
	$Crosshairs/WhipCrosshair.hide()

func hurt(damage: int) -> void:
	var actualDamage: int = damage
	if Global.playersPerks[playerId].has(Global.PerkEnum.ARMORED):
		actualDamage = int(ceil(float(damage) / 2))
	if actualDamage > 0 && alive && !Global.playersFrozen:
		if shielded:
			# todo falling text
			pass
		else:
			# todo falling text
			hp -= actualDamage
			# todo feathers
			$Hurt/Anim.stop()
			$Hurt/Anim.play("hurt")

func hurtSound(sound: AudioStreamOggVorbis) -> void:
	if alive && !shielded:
		$AudioHurt.stream = sound
		$AudioHurt.play()

func die(reason: Global.DeathEnum) -> void:
	hp = 0
	deathReason = reason

func _on_body_entered(body):
	if body.is_in_group('players'):
		if !hit:
			body.hit = true
			var collisionAnim = Res.CollisionAnimObject.instantiate()
			var animScale = (thrust.length() + body.thrust.length()) / 30
			collisionAnim.scale = Vector2(animScale, animScale)
			collisionAnim.position = global_position - ((global_position - body.global_position) / 2)
			collisionAnim.look_at(global_position)
			Global.addToScene(collisionAnim)
		# todo spiky, vampire, cuddles perks
		apply_central_impulse(body.global_position.direction_to(global_position) * 50)
		hit = false
	if body.is_in_group('cacti'):
		# todo chicken noises
		hurt(Global.DAMAGE_CACTUS)
		apply_central_impulse(body.global_position.direction_to(global_position) * 100)
	# todo wall sound
