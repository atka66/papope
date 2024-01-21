extends RigidBody2D

@export var playerId: int = 0
@onready var Lobby = get_node('/root/Lobby')

var hud: Node

var silent: bool = false
var alive: bool = true
var deathReason: Global.DeathEnum = Global.DeathEnum.DEFAULT
var hp: int = 1
var item = null
var ammo: int = 0
var contactsLava: bool = false
var shielded: bool = false
var trapped: bool = false
var isFallingIntoWater: bool = false
var inSpace: bool = false
var hit: bool = false

var thrust: Vector2 = Vector2.ZERO
var speed: int = 40
var dashMultiplier: int = 30
var frictionCustom: float = 0.1

var inputCd: bool = false

func _ready():
	hp = Global.playersMaxHp[playerId]
	Global.playersKills[playerId] = 0

	if !Global.playersCrowned[playerId]:
		$Crown.hide()
	$Shield.hide()
	$Lock.hide()
	hideCrosshairs()
	$SmokeParticles.emitting = false
	
	updateColor(Global.TEAM_COLORS[Global.playersTeam[playerId]])
	
	if !silent:
		var anim = Res.SpawnPlayerAnimObject.instantiate()
		anim.position = global_position
		Global.addToScene(anim)
	
	if Global.playersPerks[playerId].has(Global.PerkEnum.FAST):
		speed *= 2
	if Global.playersPerks[playerId].has(Global.PerkEnum.SLOW):
		speed *= 0.5
	if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		$BodyParts/Face.frame = 6
		$AudioScared.stream = Res.AudioChickenHurt.pick_random()
		chickenIdleSoundLoop()
		emitFeathers(10)
	else:
		$BodyParts/Face.frame = Global.playersSkin[playerId]
	if Global.playersPerks[playerId].has(Global.PerkEnum.REGEN):
		regenLoop()
	if Global.playersPerks[playerId].has(Global.PerkEnum.HEALTHY):
		hp *= 2
	if Global.playersPerks[playerId].has(Global.PerkEnum.UNHEALTHY):
		hp /= 2
	if Global.playersPerks[playerId].has(Global.PerkEnum.PREPARED):
		await get_tree().create_timer(0.2).timeout
		pickup(Global.getRandomPwrup())

func _input(event):
	var lhAxis: float = Input.get_joy_axis(playerId, JOY_AXIS_LEFT_X)
	var lvAxis: float = Input.get_joy_axis(playerId, JOY_AXIS_LEFT_Y)
	if abs(lhAxis) < 0.1:
		lhAxis = 0.0
	if abs(lvAxis) < 0.1:
		lvAxis = 0.0

	var lAxis: Vector2 = Vector2(lhAxis, lvAxis)

	if Global.playersPerks[playerId].has(Global.PerkEnum.REVERSE):
		lAxis *= -1
	if Global.playersPerks[playerId].has(Global.PerkEnum.NO_LEGS):
		thrust = Vector2.ZERO
	else:
		thrust = lAxis * speed

	if alive:
		var rAxis: Vector2 = Vector2(
			Input.get_joy_axis(playerId, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(playerId, JOY_AXIS_RIGHT_Y)
		)
		
		if rAxis.x == 0.0 && rAxis.y == 0.0:
			rAxis.x = 0.001
		
		if Global.playersPerks[playerId].has(Global.PerkEnum.BACKFIRE):
			rAxis *= -1
		if Global.playersPerks[playerId].has(Global.PerkEnum.RIGHT):
			rAxis.x = max(0, rAxis.x)
		
		$LookVector.position = rAxis
		$Crosshairs.rotation = rAxis.angle()
		$Crosshairs.position = rAxis
		
		var factor = 0
		match item:
			Global.PwrupEnum.REVOLVER:
				factor = 400
			Global.PwrupEnum.DYNAMITE:
				factor = 400
			Global.PwrupEnum.WHIP:
				factor = 192
		if Global.playersPerks[playerId].has(Global.PerkEnum.LONG_ARMS):
			factor *= 2
		$Crosshairs.position *= factor
		$LookVector.position *= factor
		$LookLine.set_point_position(1, rAxis * factor)

	if event.device == playerId && !inputCd:
		inputCd = true
		if Lobby != null:
			if Lobby.countdownNode == null:
				if event.is_action_pressed("skin_next"):
					Global.playersSkin[playerId] = (Global.playersSkin[playerId] + 1) % Global.SKIN_COUNT
					$BodyParts/Face.frame = Global.playersSkin[playerId]
				if ProjectSettings.get("papope/allow_players_set_options"):
						if event.is_action_pressed("game_use"):
							if Global.DEBUG:
								Global.spawnFallingLabel(Global.DEATH_STRINGS[Global.DeathEnum.DEFAULT].pick_random(), global_position, Color.LIGHT_GREEN, 3)
							Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 1) % 4
						if event.is_action_pressed("game_dash"):
							Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 3) % 4
						updateColor(Global.TEAM_COLORS[Global.playersTeam[playerId]])
		else:
			if alive && !Global.playersFrozen && !isFallingIntoWater:
				if !trapped && linear_velocity.length() < 2000 && lAxis.length() > 0:
					if event.is_action_pressed("game_dash"):
						dash(lAxis)
				if event.is_action_pressed("game_use"):
					useItem()

func regenLoop() -> void:
	await get_tree().create_timer(1.0).timeout
	heal(Global.HEAL_REGEN)
	regenLoop()

func chickenIdleSoundLoop() -> void:
	await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
	if alive && !isFallingIntoWater:
		$AudioChickenIdle.stream = Res.AudioChickenIdle.pick_random()
		$AudioChickenIdle.play()
		chickenIdleSoundLoop()

func emitFeathers(amount: int) -> void:
	var featherParticles = Res.FeatherParticlesObject.instantiate()
	featherParticles.emitting = true
	featherParticles.amount = min(amount, 30)
	add_child(featherParticles)

func updateColor(color: Color) -> void:
	var borderColor: Color = color.darkened(0.8)
	$BodyParts/Body.color = color
	$BodyParts.material.set_shader_parameter("border_color", borderColor)
	$Crosshairs.modulate = color
	$Crosshairs/DynamiteCrosshair.material.set_shader_parameter("line_color", borderColor)
	$Crosshairs/RevolverCrosshair.material.set_shader_parameter("line_color", borderColor)
	$Crosshairs/WhipCrosshair.material.set_shader_parameter("line_color", borderColor)
	$LookLine.gradient = $LookLine.gradient.duplicate()
	$LookLine.gradient.colors[0] = color * Color(1.0, 1.0, 1.0, 0.5)
	$LookLine.gradient.colors[1] = color * Color(1.0, 1.0, 1.0, 0.0)
	if hud:
		hud.setHudColor(color)

func dash(axis: Vector2) -> void:
	$AudioDash.stream = Res.AudioPlayerDash.pick_random()
	$AudioDash.play()
	
	if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		emitFeathers(5)
	
	var impulse = speed * dashMultiplier
	if Global.playersPerks[playerId].has(Global.PerkEnum.NO_LEGS) && !inSpace:
		impulse *= axis.normalized()
	else:
		impulse *= linear_velocity.normalized()
	apply_central_impulse(impulse)
	
	var dashParticles = Res.DashParticlesObject.instantiate()
	dashParticles.direction = -impulse
	dashParticles.emitting = true
	add_child(dashParticles)

func _process(delta):
	inputCd = false
	if Global.MapControllerNode != null:
		if alive:
			if contactsLava && !shielded:
				hurt(Global.DAMAGE_LAVA, null)
			if hp < 1:
				updateColor(Global.TEAM_COLORS[4])
				alive = false
				$AudioChickenIdle.stop()
				
				if isFallingIntoWater:
					# falling into water has it's own death sound
					isFallingIntoWater = false
				else:
					$AudioDeath.play()
				
				Global.spawnFallingLabel(Global.getDeathMessage(deathReason), global_position, Color.DARK_GRAY, 3)
				
				# todo death reasons
				# todo register no refunds
				
				hp = 0
				ammo = 0
				hud.hideItems()
				item = null
				hideCrosshairs()
				
				Global.shakeScreen(10)
				
				if !Global.playersFrozen:
					var aliveTeamId: int = Global.getWinnerTeam()
					if aliveTeamId != -1:
						Global.MapControllerNode.endRound(aliveTeamId)

func _physics_process(delta):
	if !isFallingIntoWater && !inSpace:
		apply_central_impulse(-linear_velocity * frictionCustom)
		if alive && !Global.playersFrozen && !trapped:
			apply_central_impulse(thrust)

func _on_remove(id):
	if playerId == id:
		queue_free()

func pickup(pwrup : Global.PwrupEnum) -> void:
	item = pwrup
	hideCrosshairs()
	$AudioPickup.play()
	var pwrupName = 'unknown'
	match pwrup:
		Global.PwrupEnum.DYNAMITE:
			pwrupName = 'dynamite'
			$Crosshairs/DynamiteCrosshair.show()
			$LookLine.show()
			ammo = 1
		Global.PwrupEnum.REVOLVER:
			pwrupName = 'revolver'
			$Crosshairs/RevolverCrosshair.show()
			$LookLine.show()
			ammo = 6
		Global.PwrupEnum.SHIELD:
			pwrupName = 'shield'
			ammo = 1
		Global.PwrupEnum.TRAP:
			pwrupName = 'trap'
			ammo = 1
		Global.PwrupEnum.WHIP:
			pwrupName = 'whip'
			$Crosshairs/WhipCrosshair.show()
			$LookLine.show()
			ammo = 5
	Global.spawnFallingLabel(pwrupName, global_position, Color.LIGHT_GREEN, 3)
	if Global.playersPerks[playerId].has(Global.PerkEnum.AKIMBO):
		ammo *= 2
	hud.pickup(item, ammo)

func useItem() -> void:
	match item:
		Global.PwrupEnum.REVOLVER:
			Global.incrementStat(playerId, Global.StatEnum.REV_USE, 1)
			apply_central_impulse(-$LookVector.position.normalized() * 400)
			var revolverRay = Res.RevolverRayObject.instantiate()
			revolverRay.position = position
			revolverRay.origin = self
			revolverRay.targetNorm = $LookVector.position.normalized()
			Global.addToScene(revolverRay)
		Global.PwrupEnum.DYNAMITE:
			Global.incrementStat(playerId, Global.StatEnum.DYN_USE, 1)
			var dynamite = Res.DynamiteObject.instantiate()
			dynamite.position = position + ($LookVector.position.normalized()) * 40
			dynamite.origin = self
			dynamite.targetNorm = $LookVector.position.normalized()
			dynamite.throwForce = $LookVector.position.length() - 20
			Global.addToScene(dynamite)
		Global.PwrupEnum.SHIELD:
			shield()
		Global.PwrupEnum.TRAP:
			Global.incrementStat(playerId, Global.StatEnum.TRP_USE, 1)
			var trap = Res.TrapObject.instantiate()
			trap.position = position
			trap.rotation_degrees += randi_range(-30, 30)
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
	#hurtSound(Res.AudioHurtRevolver) TODO maybe some time
	hurt(Global.DAMAGE_REVOLVER, playerId)
	if isRighteouslyHitBy(playerId):
		Global.incrementStat(playerId, Global.StatEnum.REV_HIT, 1)
	apply_central_impulse(normal * 400)

func getTrapped(playerId: int) -> void:
	hurtSound(Res.AudioHurtTrap)
	hurt(Global.DAMAGE_TRAP, playerId)
	# todo was just killed?
	#TODO stepped in his own trap?
	trapped = true
	$Lock.show()
	$Lock/Timer.start(2.0)

func getWhipped(playerId: int, normal: Vector2) -> void:
	hurtSound(Res.AudioHurtWhip)
	hurt(Global.DAMAGE_WHIP, playerId)
	# todo was just killed?
	apply_central_impulse(normal * 2000)

func getZapped() -> void:
	hurtSound(Res.AudioContactCactus.pick_random()) # TODO maybe something else
	hurt(Global.DAMAGE_SPACERAY, null)
	#todo was just killed?
	
	var vector: Vector2 = Vector2(-linear_velocity.x, 0)
	var vel = Vector2.RIGHT
	if global_position.x < 672:
		vel.x *= -1
	apply_central_impulse(vector + (vel * 1600))

func untrap():
	trapped = false
	$Lock.hide()

func directExplosion():
	hurtSound(Res.AudioHurtDynamite)

func shield() -> void:
	shielded = true
	Global.spawnFallingLabel("shielded!", global_position, Color.LIGHT_BLUE, 3)
	$Shield.show()
	$AudioShieldStart.play()
	$Shield/Anim.stop()
	$Shield/Anim.play('shielded')

func unshield() -> void:
	shielded = false
	$Shield.hide()
	$AudioShieldEnd.play()

func hideCrosshairs() -> void:
	$Crosshairs/DynamiteCrosshair.hide()
	$Crosshairs/RevolverCrosshair.hide()
	$Crosshairs/WhipCrosshair.hide()
	$LookLine.hide()

func hurt(damage: int, inflictorPlayerId) -> void:
	var actualDamage: int = damage
	if Global.playersPerks[playerId].has(Global.PerkEnum.ARMORED):
		actualDamage = int(ceil(float(damage) / 2))
	if actualDamage > 0 && alive && !Global.playersFrozen:
		var fallingMessageSize = int(actualDamage / 10) + 1
		if shielded:
			Global.spawnFallingLabel('0', global_position, Color.WHITE, fallingMessageSize)
		else:
			Global.spawnFallingLabel(str(int(actualDamage)), global_position, Color.TOMATO, fallingMessageSize)
			hp -= actualDamage
			if inflictorPlayerId != null && Global.playersPerks[inflictorPlayerId].has(Global.PerkEnum.VAMPIRE):
				Global.getPlayer(inflictorPlayerId).heal(actualDamage)
			if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN) && actualDamage > 5:
				emitFeathers(actualDamage)
			$Hurt/Anim.stop()
			$Hurt/Anim.play("hurt")

func heal(amount) -> void:
	if amount > 0 && alive && !Global.playersFrozen:
		Global.spawnFallingLabel(str(int(amount)), global_position, Color.LIGHT_GREEN, int(amount / 10) + 1)
		hp = min(hp + amount, Global.playersMaxHp[playerId])
		$Hurt/Anim.stop()
		$Hurt/Anim.play("heal")

func hurtSound(sound: AudioStreamOggVorbis) -> void:
	if alive && !shielded:
		if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
			$AudioHurt.stream = Res.AudioChickenHurt.pick_random()
		else:
			$AudioHurt.stream = sound
		$AudioHurt.play()

func fallIntoWater() -> void:
	$CollisionShape.set_deferred("disabled", true)
	isFallingIntoWater = true
	if alive:
		$AudioScared.play()
	gravity_scale = 10
	var vector = -linear_velocity
	var vel = Vector2(0.7, -1.0)
	if global_position.x < 680:
		vel.x *= -1
	apply_central_impulse(vector + (vel * 1000))
	await get_tree().create_timer(0.6).timeout
	$AudioFellInWater.play()
	if !Global.playersFrozen:
		die(Global.DeathEnum.WATER)
	gravity_scale = 0

func die(reason: Global.DeathEnum) -> void:
	hp = 0
	deathReason = reason

func enteredLava() -> void:
	contactsLava = true
	$SmokeParticles.emitting = true
	$AudioInLava.play()

func exitedLava() -> void:
	contactsLava = false
	$SmokeParticles.emitting = false

func _integrate_forces(state):
	Global.pacmanWrap(state)

func _on_body_entered(body):
	if body.is_in_group('players'):
		if !hit:
			body.hit = true
			var collisionAnim = Res.CollisionAnimObject.instantiate()
			var animScale = (thrust.length() + body.thrust.length()) / 60
			collisionAnim.scale = Vector2(animScale, animScale)
			collisionAnim.position = global_position - ((global_position - body.global_position) / 2)
			collisionAnim.look_at(global_position)
			Global.addToScene(collisionAnim)
		apply_central_impulse(body.global_position.direction_to(global_position) * 50)
		hit = false
	if body.is_in_group('cacti'):
		# todo maybe hurt sound for the non-chicken as well?
		if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
			hurtSound(Res.AudioChickenHurt.pick_random())
		hurt(Global.DAMAGE_CACTUS, null)
		body.bounce()
		body.pinch()
		apply_central_impulse(body.global_position.direction_to(global_position) * 100)
	# todo wall sound

func isTeammate(otherPlayerId) -> bool:
	return Global.playersTeam[otherPlayerId] == Global.playersTeam[playerId]

func isRighteouslyHitBy(inflictorId) -> bool:
	return alive && !shielded && !isTeammate(inflictorId)
