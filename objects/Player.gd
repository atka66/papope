extends RigidBody2D

export var playerId = 0

var inLobby = false
var hit = false
var alive = true
var hp = Global.options['hp'][Global.optionsSelected['hp']]
var item = null
var ammo = 0
var contactsLava = false
var outsideCntdwn = 60 * 3
var timeBombCd = 60 * 20
var invulnerable = false
var fallWater = false
var trapped = false
var inSpace = false

var thrust = Vector2.ZERO
var speed = 20
var dashMul = 30
var frictionCustom = 0.1

var color = Global.TEAM_COLORS[0]
var inputCd = false

var wrapPosition = null

func _ready():
	$InvulAnim.play()
	$InvulAnim.hide()
	if !Global.playersCrowned[playerId]:
		$Crown.hide()
	$Crosshair.hide()
	$Lock.hide()
	$WhiplashAnim.hide()
	$OutsideLabel.hide()
	$SmokeParticles.emitting = false
	inLobby = get_tree().get_current_scene().get_name() == 'Lobby'
	if !inLobby:
		var hud = Res.Hud.instance()
		var position = Vector2.ZERO
		if playerId == 0: position = Vector2(-120, 4)
		if playerId == 1: position = Vector2(688, 4)
		if playerId == 2: position = Vector2(-120, 324)
		if playerId == 3: position = Vector2(688, 324)
		hud.name = 'Hud' + str(playerId)
		hud.position = position
		hud.player = self
		hud.fromRight = (playerId % 2 == 1)
		get_parent().add_child(hud)
	color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Body.modulate = color
	$Crosshair.modulate = color
	$Face.frame = Global.playersSkin[playerId]
	var spawnAnim = Res.SpawnAnim.instance()
	spawnAnim.position = global_position
	get_tree().get_root().add_child(spawnAnim)
	
	if Global.playersPerks[playerId].has(Global.PerkEnum.FAST):
		speed *= 2
	if Global.playersPerks[playerId].has(Global.PerkEnum.SLOW):
		speed *= 0.5

func isPressed(event, action):
	return event.is_action_pressed(action) && Input.is_action_just_pressed(action)

func _input(event):
	var lhAxis = Input.get_joy_axis(playerId, JOY_AXIS_0)
	var lvAxis = Input.get_joy_axis(playerId, JOY_AXIS_1)
	if abs(lhAxis) < 0.1 : lhAxis = 0.0
	if abs(lvAxis) < 0.1 : lvAxis = 0.0
	
	if Global.playersPerks[playerId].has(Global.PerkEnum.REVERSE):
		lhAxis *= -1
		lvAxis *= -1
	
	if Global.playersPerks[playerId].has(Global.PerkEnum.NO_LEGS):
		thrust = Vector2.ZERO
	else:
		thrust = Vector2(lhAxis, lvAxis) * speed

	if alive:
		var aimVector = Vector2(
			Input.get_joy_axis(playerId, JOY_AXIS_2), 
			Input.get_joy_axis(playerId, JOY_AXIS_3)
		)
		# correct axis if pointing at origin
		if aimVector.x == 0.0 && aimVector.y == 0.0:
			aimVector.x = 0.001;

		if Global.playersPerks[playerId].has(Global.PerkEnum.BACKFIRE):
			aimVector *= -1
		
		if Global.playersPerks[playerId].has(Global.PerkEnum.RIGHT):
			aimVector.x = max(0, aimVector.x)

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
			if !get_node('/root/Lobby').countingDown:
				if isPressed(event, "pl_skin_next"):
					Global.playersSkin[playerId] = (Global.playersSkin[playerId] + 1) % Global.SKIN_COUNT
				if isPressed(event, "pl_game_use"):
					Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 1) % 4
				if isPressed(event, "pl_game_dash"):
					Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 3) % 4
				$Face.frame = Global.playersSkin[playerId]
				$Body.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]
		else:
			if alive && !Global.playersFrozen && !fallWater:
				if !trapped && linear_velocity.length() < 1000:
					if isPressed(event, 'pl_game_dash'):
						$AudioDash.stream = Res.AudioPlayerDash[randi() % len(Res.AudioPlayerDash)]
						$AudioDash.play()
						if Global.playersPerks[playerId].has(Global.PerkEnum.NO_LEGS) && !inSpace:
							apply_central_impulse(Vector2(lhAxis, lvAxis).normalized() * speed * dashMul)
						else:
							apply_central_impulse(linear_velocity.normalized() * speed * dashMul)
				if isPressed(event, 'pl_game_use'):
					useItem()

func _process(delta):
	inputCd = false
	if !inLobby:
		if alive:
			if contactsLava:
				hurt(1)
			if outsideCntdwn < 1 || timeBombCd < 1:
				hp = 0
			if hp < 1:
				$Body.modulate = Global.TEAM_COLORS[4]
				alive = false
				spawnFallingMessage(
					Global.DEATH_STRINGS[randi() % len(Global.DEATH_STRINGS)]
					, Color.darkgray, 3, Res.AudioPlayerDeath
				)
				if invulnerable:
					Global.registerAchievement(playerId, Global.AchiEnum.NO_REFUNDS)
				hp = 0
				ammo = 0
				item = null
				$Crosshair.hide()
				$TimebombLabel.hide()

				if !Global.playersFrozen:
					var aliveTeamId = Global.getWinnerTeam();
					if aliveTeamId != -1: # round is over
						get_tree().get_nodes_in_group('controllers')[0].endRound(aliveTeamId)
			
			if !Global.playersFrozen && !fallWater:
				if Global.playersPerks[playerId].has(Global.PerkEnum.TIME_BOMB):
					$TimebombLabel.global_position = position
					$TimebombLabel.global_position.y -= 5
					$TimebombLabel.set_text(str(ceil(float(timeBombCd) / 60)))
					$TimebombLabel.show()
					timeBombCd -= 1
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

func _on_Player_body_entered(body):
	if body.is_in_group('players'):
		if !hit:
			body.hit = true
			var collisionAnim = Res.CollisionAnim.instance()
			var animScale = (thrust.length() + body.thrust.length()) / 20
			collisionAnim.scale = Vector2(animScale, animScale)
			collisionAnim.play()
			collisionAnim.position = body.global_position - ((body.global_position - global_position) / 2)
			collisionAnim.look_at(body.global_position)
			get_tree().get_current_scene().add_child(collisionAnim)
		if body.alive:
			if Global.playersPerks[playerId].has(Global.PerkEnum.SPIKY):
				body.hurt(5)
				$AudioRevHit.play()
			if Global.playersPerks[playerId].has(Global.PerkEnum.CUDDLES):
				heal(5)
				#TODO some audio
				#$AudioRevHit.play()
		apply_central_impulse(body.global_position.direction_to(global_position) * 50)
		hit = false
	if body.is_in_group('cacti'):
		$AudioHurtCactus.stream = Res.AudioPlayerHurtCactus[randi() % len(Res.AudioPlayerHurtCactus)]
		$AudioHurtCactus.play()
		hurt(10)
		apply_central_impulse(body.global_position.direction_to(global_position) * 100)
	if body.is_in_group('blockcollidors'):
		if linear_velocity.length() > 250:
			$AudioCollisionBlock.play()

func extendVectorTo(vector, length):
	if vector.length() == 0:
		return Vector2.RIGHT
	return vector * (float(length) / vector.length())

func pickup(pwrup):
	spawnFallingMessage(pwrup, Color.lightgreen, 2, Res.AudioPwrupPickup)
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
	if Global.playersPerks[playerId].has(Global.PerkEnum.AKIMBO):
		ammo *= 2

func trap():
	trapped = true
	$Lock.show()
	spawnFallingMessage("trapped!", Color.tomato, 2, null)
	yield(get_tree().create_timer(2.0), "timeout")
	trapped = false
	$Lock.hide()

func useItem():
		if item == 'revolver':
			Global.incrementStat(playerId, Global.StatEnum.REV_USE, 1)
			var revolverRay = Res.RevolverRay.instance()
			var hitPosition = global_position + $HitScan.cast_to
			if $HitScan.is_colliding():
				var collider = $HitScan.get_collider()
				hitPosition = $HitScan.get_collision_point()
				if collider.is_in_group('players'):
					collider.get_node("AudioRevHit").play()
					if collider.wouldRighteouslyBeHitBy(playerId):
						Global.incrementStat(playerId, Global.StatEnum.REV_HIT, 1)
					collider.hurt(20)
					if wasTeammateJustKilled(collider):
						Global.registerAchievement(playerId, Global.AchiEnum.TRAITOR)
					collider.apply_central_impulse($HitScan.cast_to.normalized() * 100)
				elif collider.is_in_group('ghosts'):
					Global.incrementStat(playerId, Global.StatEnum.GHOST_KILL, 1)
					collider.die()
				else:
					var ricochet = Res.RevolverRicochet.instance()
					ricochet.position = hitPosition
					get_parent().add_child(ricochet)
			revolverRay.position = position
			revolverRay.rotation = $HitScan.cast_to.angle()
			revolverRay.length = (position - hitPosition).length()
			get_tree().get_current_scene().add_child(revolverRay)
		if item == 'dynamite':
			Global.incrementStat(playerId, Global.StatEnum.DYN_USE, 1)
			var dynamite = Res.Dynamite.instance()
			dynamite.position = position + ($HitScan.cast_to.normalized()) * 16
			dynamite.originPlayerId = playerId
			dynamite.apply_central_impulse($HitScan.cast_to * 190)
			get_tree().get_current_scene().add_child(dynamite)
		if item == 'shield':
			$InvulAnim/Audio.stream = Res.AudioShieldStart
			$InvulAnim/Audio.play()
			invulnerable = true
			spawnFallingMessage("shielded!", Color.lightblue, 2, null)
			$InvulAnim.show()
			$InvulAnim/Timer.start(5)
		if item == 'trap':
			$AudioPlaceTrap.play()
			Global.incrementStat(playerId, Global.StatEnum.TRP_USE, 1)
			var trap = Res.Trap.instance()
			trap.originPlayerId = playerId
			trap.rotation_degrees += (randi() % 60) - 30
			trap.position = position
			get_tree().get_current_scene().add_child(trap)
		if item == 'whip':
			Global.incrementStat(playerId, Global.StatEnum.WHP_USE, 1)
			var angle = $HitScan.cast_to.angle()
			$WhiplashAnim.rotation = angle
			$WhiplashAnim.frame = 0
			$WhiplashAnim.show()
			$WhiplashAnim.play()
			var whipcrackAnim = Res.WhipcrackAnim.instance()
			var hitPosition = global_position + $HitScan.cast_to
			if $HitScan.is_colliding():
				var collider = $HitScan.get_collider()
				if collider.is_in_group('players'):
					collider.get_node('AudioHurtWhip').play()
					if collider.wouldRighteouslyBeHitBy(playerId):
						Global.incrementStat(playerId, Global.StatEnum.WHP_HIT, 1)
					hitPosition = $HitScan.get_collision_point()
					collider.hurt(30)
					if wasTeammateJustKilled(collider): # if teammate was just killed
						Global.registerAchievement(playerId, Global.AchiEnum.TRAITOR)
					collider.apply_central_impulse($HitScan.cast_to.normalized() * 1000)
				if collider.is_in_group('ghosts'):
					Global.incrementStat(playerId, Global.StatEnum.GHOST_KILL, 1)
					collider.die()
			whipcrackAnim.position = hitPosition
			get_tree().get_current_scene().add_child(whipcrackAnim)
		if item != null:
			ammo -= 1
			if ammo < 1:
				item = null
				$Crosshair.hide()

func _endInvul():
	$InvulAnim/Timer.stop()
	$InvulAnim/Audio.stream = Res.AudioShieldEnd
	$InvulAnim/Audio.play()
	invulnerable = false
	$InvulAnim.hide()

func hurt(damage):
	var actualDamage = damage
	if Global.playersPerks[playerId].has(Global.PerkEnum.ARMORED):
		actualDamage = int(ceil(float(damage) / 2))
	if actualDamage > 0 && alive && !Global.playersFrozen:
		var fallingMessageSize = int(actualDamage / 20) + 1
		if invulnerable:
			spawnFallingMessage('0', Color.white, fallingMessageSize, null)
		else:
			spawnFallingMessage(str(int(actualDamage)), Color.tomato, fallingMessageSize, null)
			hp -= actualDamage;
			$Hurt/HurtAnim.stop()
			$Hurt/HurtAnim.play('hurt')

func heal(amount):
	if amount > 0 && alive && !Global.playersFrozen:
		var fallingMessageSize = int(amount / 20) + 1
		spawnFallingMessage(str(int(amount)), Color.lightgreen, fallingMessageSize, null)
		hp = min(hp + amount, Global.options['hp'][Global.optionsSelected['hp']])
		$Hurt/HurtAnim.stop()
		$Hurt/HurtAnim.play('heal')

func _on_WhiplashAnim_animation_finished():
	$WhiplashAnim.hide()

func isOutside():
	return global_position.x < 0 || global_position.x > 680 || global_position.y < 0 || global_position.y > 384
		
func wasTeammateJustKilled(other):
	return other.alive && other.hp <= 0 && isTeammate(other.playerId)

func isTeammate(otherPlayerId):
	return Global.playersTeam[otherPlayerId] == Global.playersTeam[playerId]

func wouldRighteouslyBeHitBy(inflictorId):
	return alive && !invulnerable && !isTeammate(inflictorId)

func spawnFallingMessage(text, color, size, audio):
	var message = Res.FallingMessage.instance()
	message.text = text
	message.color = color
	message.size = size
	message.audio = audio
	message.position = global_position
	get_parent().add_child(message)

# handle wrapping on pacman map
func _integrate_forces(state):
	if wrapPosition != null:
		state.transform.origin = wrapPosition
		wrapPosition = null
