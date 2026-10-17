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
var kbAimActive: bool = false
var lavaAccum: float = 0.0
var onConveyorBelt: bool = false

# online multiplayer: only the owning peer polls hardware for this player
var isLocal: bool = true
var netMove: Vector2 = Vector2.ZERO
var remoteAim: Vector2 = Vector2.ZERO
var hasRemoteAim: bool = false
var _sendAccum: float = 0.0
var _lastTeam: int = -1
var _lastSkin: int = -1
var _lastShielded: bool = false
# guest-side snapshot interpolation for remote players
const NET_INTERP_DELAY := 0.1
var netSnaps: Array = []

func _ready():
	if Net.isOnline and not isLocal and not Net.isHost:
		# Guests never integrate non-owned bodies anywhere (map or lobby):
		# the host simulates everything, snapshots drive the rest.
		freeze = true
	if !Lobby && Global.MapControllerNode.isNightclub:
		$BodyParts/Face.modulate = Color.BLACK
		$Crown.modulate = Color.BLACK
		$LookLine.z_as_relative = false
		$LookLine.z_index = 3
		$Crosshairs.z_as_relative = false
		$Crosshairs.z_index = 3
	
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

func ownsKeyboard() -> bool:
	if Net.isOnline:
		return isLocal
	return Global.playersInputMode[playerId] == Global.InputMode.KB

func getMoveVector() -> Vector2:
	# Online: host drives remote slots from forwarded inputs, clients hold still
	# between host state syncs (never poll another peer's gamepad).
	if Net.isOnline and not isLocal:
		if Net.isHost:
			return netMove
		return Vector2.ZERO
	var lAxis := Vector2.ZERO
	var joyDevice := Global.deviceForPlayer(playerId)
	if joyDevice >= 0:
		var lhAxis: float = Input.get_joy_axis(joyDevice, JOY_AXIS_LEFT_X)
		var lvAxis: float = Input.get_joy_axis(joyDevice, JOY_AXIS_LEFT_Y)
		if abs(lhAxis) < 0.1:
			lhAxis = 0.0
		if abs(lvAxis) < 0.1:
			lvAxis = 0.0
		lAxis = Vector2(lhAxis, lvAxis)
	if ownsKeyboard() && Global.enableHotkeys:
		# ignore WASD while typing in a text field (lobby feedback)
		lAxis += Input.get_vector("kb_move_left", "kb_move_right", "kb_move_up", "kb_move_down")
		if lAxis.length() > 1.0:
			lAxis = lAxis.normalized()
	if Global.playersPerks[playerId].has(Global.PerkEnum.REVERSE):
		lAxis *= -1
	return lAxis

func getAimVector() -> Vector2:
	if Net.isOnline and not isLocal and hasRemoteAim:
		return remoteAim
	var stick := Vector2.ZERO
	var joyDevice := Global.deviceForPlayer(playerId)
	if joyDevice >= 0:
		stick = Vector2(
			Input.get_joy_axis(joyDevice, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(joyDevice, JOY_AXIS_RIGHT_Y)
		)
	if stick.length() > 0.15:
		kbAimActive = false
	elif not Net.isOnline and Global.playersInputMode[playerId] == Global.InputMode.KB:
		kbAimActive = true # locked KB: mouse aim stays on, no stick to steal it

	var rAxis: Vector2
	var mouseDist: float = -1.0
	if ownsKeyboard() && kbAimActive:
		var toMouse: Vector2 = get_global_mouse_position() - global_position
		if toMouse.length() < 1.0:
			toMouse = Vector2.RIGHT
		mouseDist = toMouse.length()
		rAxis = toMouse.normalized()
	else:
		rAxis = stick
		if rAxis.x == 0.0 && rAxis.y == 0.0:
			rAxis.x = 0.001

	if Global.playersPerks[playerId].has(Global.PerkEnum.BACKFIRE):
		rAxis *= -1
	if Global.playersPerks[playerId].has(Global.PerkEnum.RIGHT):
		rAxis.x = max(0, rAxis.x)

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
	if mouseDist >= 0.0:
		return rAxis.normalized() * min(mouseDist, float(factor))
	return rAxis * factor

func updateAimVisuals() -> void:
	var rAxis: Vector2 = getAimVector()
	$LookVector.position = rAxis
	$Crosshairs.rotation = rAxis.angle()
	$Crosshairs.position = rAxis
	$LookLine.set_point_position(1, rAxis)

func _input(event):
	# Online: only the owning peer drives this player (device ids are per-machine).
	if Net.isOnline and not isLocal:
		return
	if ownsKeyboard():
		if event is InputEventMouseMotion || event is InputEventMouseButton:
			kbAimActive = true

	var lAxis: Vector2 = getMoveVector()

	var padDash: bool = event.is_action_pressed("game_dash")
	var padUse: bool = event.is_action_pressed("game_use")
	var kbDash: bool = ownsKeyboard() && event.is_action_pressed("kb_dash")
	var kbUse: bool = ownsKeyboard() && event.is_action_pressed("kb_use")
	var ownsEvent: bool = (Net.isOnline && isLocal) || (!Net.isOnline && event.device == Global.deviceForPlayer(playerId))
	if ownsEvent || kbDash || kbUse:
		if Lobby != null:
			if Lobby.countdownNode == null && !ProjectSettings.get("papope/hosted_mode"):
				if Net.isOnline:
					_onlineLobbyInput(event, padUse, padDash, kbDash, kbUse)
				elif (Global.enableHotkeys && event.is_action_pressed("skin_next") || padUse || padDash) && !inputCd:
					inputCd = true
					if event.is_action_pressed("skin_next"):
						Global.playersSkin[playerId] = (Global.playersSkin[playerId] + 1) % Global.SKIN_COUNT
						$BodyParts/Face.frame = Global.playersSkin[playerId]
					if padUse:
						if Global.DEBUG:
							Global.spawnFallingLabel(Global.DEATH_STRINGS[Global.DeathEnum.DEFAULT].pick_random(), global_position, Color.LIGHT_GREEN, 3)
						Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 1) % 4
					if padDash:
						Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 3) % 4
					updateColor(Global.TEAM_COLORS[Global.playersTeam[playerId]])
		else:
			if alive && !Global.playersFrozen && !isFallingIntoWater:
				if !trapped && linear_velocity.length() < 2000 && lAxis.length() > 0:
					if (padDash || kbDash) && !inputCd:
						inputCd = true
						_onlineDash(lAxis)
				if (padUse || kbUse) && !inputCd:
					inputCd = true
					_onlineUse()

func _onlineLobbyInput(event, padUse: bool, padDash: bool, kbDash: bool, kbUse: bool) -> void:
	if (Global.enableHotkeys && event.is_action_pressed("skin_next") || padUse || padDash || kbDash || kbUse) && !inputCd:
		inputCd = true
		if event.is_action_pressed("skin_next"):
			_requestLobbyChange("skin", (Global.playersSkin[playerId] + 1) % Global.SKIN_COUNT)
		if padUse || kbUse:
			_requestLobbyChange("team", (Global.playersTeam[playerId] + 1) % 4)
		if padDash || kbDash:
			_requestLobbyChange("team", (Global.playersTeam[playerId] + 3) % 4)
	if event.is_action_pressed("accept") || (ownsKeyboard() && event.is_action_pressed("kb_accept")):
		if Global.getNumberOfTeams() > 1:
			if Net.isHost:
				Net.begin_countdown()
		else:
			Lobby.warnCannotStart()
	if event.is_action_pressed("cancel") || (ownsKeyboard() && event.is_action_pressed("kb_cancel")):
		if Lobby.countdownNode != null:
			if Net.isHost:
				Net.cancel_countdown()
		else:
			Global.playersCrowned[playerId] = false
			Net.leave()
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _requestLobbyChange(kind: String, value) -> void:
	if Net.isHost:
		Net.request_lobby_change(kind, playerId, value)
	else:
		Net.request_lobby_change(kind, playerId, value)

func _onlineDash(axis: Vector2) -> void:
	if !Net.isOnline:
		dash(axis)
		return
	if Net.isHost:
		# notify_action executes locally and broadcasts (no relay echo),
		# so the host must not pre-execute or the action fires twice.
		Net.notify_action(playerId, "dash", getAimVector(), axis)
	else:
		Net.request_action(playerId, "dash", getAimVector(), axis)

func _onlineUse() -> void:
	if !Net.isOnline:
		useItem()
		return
	if Net.isHost:
		# Same single-execution rule as dash above.
		Net.notify_action(playerId, "use", getAimVector(), getMoveVector())
	else:
		Net.request_action(playerId, "use", getAimVector(), getMoveVector())

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
	if Global.playersPerks[playerId].has(Global.PerkEnum.NO_LEGS):
		thrust = Vector2.ZERO
	else:
		thrust = getMoveVector() * speed
	if alive:
		updateAimVisuals()
	if Global.MapControllerNode != null:
		if alive:
			# Lava damage is host-authorized; guests keep smoke/sound locally
			# (enteredLava) while hp converges via state sync.
			if contactsLava && !shielded && (not Net.isOnline or Net.isHost):
				lavaAccum += Global.DPS_LAVA * delta
				while lavaAccum >= 1.0:
					lavaAccum -= 1.0
					hurt(1, null)
			if hp < 1:
				updateColor(Global.TEAM_COLORS[4])
				alive = false
				if hud:
					hud.die()
				$AudioChickenIdle.stop()
				
				if isFallingIntoWater:
					# falling into water has it's own death sound
					isFallingIntoWater = false
				else:
					$AudioDeath.play()
				
				_netLabel(Global.getDeathMessage(deathReason), global_position, Color.DARK_GRAY, 3)
				
				if shielded:
					Global.registerAchievement(playerId, Global.AchiEnum.NO_REFUNDS)

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
	if _isNetGhost():
		_interpRemote()

func _isNetGhost() -> bool:
	return Net.isOnline and not isLocal and freeze

func _physics_process(delta):
	# Online ghosts don't integrate locally (frozen): snapshots drive them.
	var coast := _isNetGhost()
	if !isFallingIntoWater && !inSpace && !coast:
		apply_central_impulse(-linear_velocity * frictionCustom)
		if alive && !Global.playersFrozen && !trapped:
			apply_central_impulse(thrust)
	if Net.isOnline:
		if Lobby != null:
			_refreshLobbyVisuals()
		if isLocal && !Net.isHost && (Lobby != null || alive):
			# Forward owned inputs in map and lobby alike; the host
			# simulates every non-owned body from these.
			_sendAccum += delta
			if _sendAccum >= Net.STATE_RATE:
				_sendAccum = 0.0
				Net.send_input(playerId, getMoveVector(), getAimVector())

func _refreshLobbyVisuals() -> void:
	if Global.playersTeam[playerId] != _lastTeam:
		_lastTeam = Global.playersTeam[playerId]
		updateColor(Global.TEAM_COLORS[_lastTeam])
	if Global.playersSkin[playerId] != _lastSkin:
		_lastSkin = Global.playersSkin[playerId]
		if !Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
			$BodyParts/Face.frame = _lastSkin

func apply_net_state(s: Array) -> void:
	# s = [slot, pos, vel, hp, alive, itemInt, ammo, shielded, aim, trapped]
	var targetPos: Vector2 = s[1]
	var targetVel: Vector2 = s[2]
	if Net.isOnline and not Net.isHost and not isLocal:
		# Remote body on a guest: buffer the snapshot, interpolation renders
		# position AND aim (crosshair would step at 20Hz otherwise).
		var incomingAim: Vector2 = s[8]
		netSnaps.append({"t": Time.get_ticks_msec() / 1000.0, "pos": targetPos, "vel": targetVel, "aim": incomingAim})
		while netSnaps.size() > 4:
			netSnaps.pop_front()
		if not hasRemoteAim:
			remoteAim = incomingAim
			hasRemoteAim = true
	elif isLocal:
		# Own predicted body: fully trust local sim while the error is small,
		# snap only on large divergence (dash, knockback, teleport).
		var err := global_position.distance_to(targetPos)
		if err > 32.0:
			global_position = targetPos
			linear_velocity = targetVel
		elif err > 10.0:
			linear_velocity = targetVel
			global_position = global_position.lerp(targetPos, 0.4)
	else:
		# Host driving a remote slot: direct sets stay smooth (it simulates).
		global_position = targetPos
		linear_velocity = targetVel
	hp = int(s[3])
	shielded = bool(s[7])
	if not (Net.isOnline and not Net.isHost and not isLocal):
		remoteAim = s[8]
		hasRemoteAim = true
	var itemInt := int(s[5])
	var newItem = null
	if itemInt >= 0:
		newItem = itemInt
	if newItem != item:
		item = newItem
		ammo = int(s[6])
		_syncCrosshairs()
		if hud:
			hud.syncInventory(item, ammo)
		if item != null:
			_gainFeedback()
	elif hud and item != null and int(s[6]) != ammo:
		ammo = int(s[6])
		hud.updateAmmo(item, ammo)
	if shielded != _lastShielded:
		_lastShielded = shielded
		if shielded:
			$Shield.show()
		else:
			$Shield.hide()
			if not isLocal:
				# Remote copies have no expiry anim; mirror the end sound too
				# (local copies play it via their own unshield anim).
				$AudioShieldEnd.play()
	# s[9]: trapped flag (host-side trap springs). Apply visuals only;
	# damage/achievements already ran on the host.
	if s.size() >= 10:
		var trappedState := bool(s[9])
		if trappedState and not trapped:
			trapped = true
			$Lock.show()
			$Lock/Timer.start(2.0)
		elif not trappedState and trapped:
			untrap()
	var newAlive := bool(s[4])
	if alive and not newAlive:
		alive = false
		updateColor(Global.TEAM_COLORS[4])
		if hud:
			hud.die()
			hud.hideItems()
		hideCrosshairs()
		$AudioDeath.play()
	elif not alive and newAlive:
		alive = true
		updateColor(Global.TEAM_COLORS[Global.playersTeam[playerId]])

func _netLabel(text: String, pos: Vector2, color: Color, size: int) -> void:
	# Damage numbers are host-truth: guests skip local spawns and render the
	# host's broadcast instead, so every screen shows the same numbers.
	if Net.isOnline and not Net.isHost:
		return
	Global.spawnFallingLabel(text, pos, color, size)
	if Net.isOnline:
		Net.damage_number(text, pos, color, size)

func _gainFeedback() -> void:	# Host-side pickup() already played full feedback there; this mirrors the
	# noticeable bits on guests when the synced item arrives.
	$AudioPickup.play()
	var pwrupName := str(Global.PwrupEnum.keys()[int(item)]).to_lower()
	Global.spawnFallingLabel(pwrupName, global_position, Color.LIGHT_GREEN, 3)

func _syncCrosshairs() -> void:
	hideCrosshairs()
	if item == null:
		return
	match item:
		Global.PwrupEnum.DYNAMITE:
			$Crosshairs/DynamiteCrosshair.show()
			$LookLine.show()
		Global.PwrupEnum.REVOLVER:
			$Crosshairs/RevolverCrosshair.show()
			$LookLine.show()
		Global.PwrupEnum.WHIP:
			$Crosshairs/WhipCrosshair.show()
			$LookLine.show()

func _interpRemote() -> void:
	# Snapshot interpolation: render where the body was NET_INTERP_DELAY ago,
	# lerped between the two bracketing snapshots. Exact on path, no trailing.
	if netSnaps.is_empty():
		return
	var now := Time.get_ticks_msec() / 1000.0
	var rt := now - NET_INTERP_DELAY
	var d1: Dictionary = {}
	while netSnaps.size() > 2:
		d1 = netSnaps[1]
		if float(d1.get("t", 0.0)) > rt:
			break
		netSnaps.pop_front()
	var a: Dictionary = netSnaps[0]
	if netSnaps.size() < 2:
		var pa0: Vector2 = a["pos"]
		global_position = global_position.lerp(pa0, 0.5)
		linear_velocity = a["vel"]
		remoteAim = a.get("aim", remoteAim)
		return
	var b: Dictionary = netSnaps[1]
	var ta := float(a.get("t", 0.0))
	var tb := float(b.get("t", 0.0))
	var pa: Vector2 = a["pos"]
	var pb: Vector2 = b["pos"]
	var va: Vector2 = a["vel"]
	var vb: Vector2 = b["vel"]
	var aa: Vector2 = a.get("aim", remoteAim)
	var ab: Vector2 = b.get("aim", remoteAim)
	if rt <= ta:
		global_position = pa
		linear_velocity = va
		remoteAim = aa
		return
	if rt >= tb:
		var over := minf(rt - tb, 0.05)
		global_position = pb + vb * over
		linear_velocity = vb
		remoteAim = ab
		return
	var f := clampf((rt - ta) / maxf(tb - ta, 0.001), 0.0, 1.0)
	global_position = pa.lerp(pb, f)
	linear_velocity = va.lerp(vb, f)
	remoteAim = aa.lerp(ab, f)

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

func getShot(originPlayerId: int, normal: Vector2) -> void:
	#hurtSound(Res.AudioHurtRevolver) TODO maybe some time
	hurt(Global.DAMAGE_REVOLVER, originPlayerId)
	if isRighteouslyHitBy(originPlayerId):
		Global.incrementStat(originPlayerId, Global.StatEnum.REV_HIT, 1)
	if isJustKilled():
		die(Global.DeathEnum.REVOLVER)
		if isTeammate(originPlayerId):
			Global.registerAchievement(originPlayerId, Global.AchiEnum.TRAITOR)
		else:
			Global.addKill(originPlayerId)
	apply_central_impulse(normal * 400)

func getTrapped(originPlayerId: int) -> void:
	hurtSound(Res.AudioHurtTrap)
	hurt(Global.DAMAGE_TRAP, originPlayerId)
	if isRighteouslyHitBy(originPlayerId):
		Global.incrementStat(originPlayerId, Global.StatEnum.TRP_HIT, 1)
	if isJustKilled():
		die(Global.DeathEnum.TRAP)
		if playerId != originPlayerId:
			if isTeammate(originPlayerId):
				Global.registerAchievement(originPlayerId, Global.AchiEnum.TRAITOR)
			else:
				Global.addKill(originPlayerId)
	if alive && playerId == originPlayerId:
		Global.registerAchievement(playerId, Global.AchiEnum.CARELESS)
	trapped = true
	$Lock.show()
	$Lock/Timer.start(2.0)

func getWhipped(originPlayerId: int, normal: Vector2) -> void:
	hurtSound(Res.AudioHurtWhip)
	hurt(Global.DAMAGE_WHIP, originPlayerId)
	if isRighteouslyHitBy(originPlayerId):
		Global.incrementStat(originPlayerId, Global.StatEnum.WHP_HIT, 1)
	if isJustKilled():
		die(Global.DeathEnum.WHIP)
		if isTeammate(originPlayerId):
			Global.registerAchievement(originPlayerId, Global.AchiEnum.TRAITOR)
		else:
			Global.addKill(originPlayerId)
	apply_central_impulse(normal * 2000)

func getZapped() -> void:
	hurtSound(Res.AudioContactCactus.pick_random()) # TODO maybe something else
	hurt(Global.DAMAGE_SPACERAY, null)
	if isJustKilled():
		die(Global.DeathEnum.LASER)

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
	if Net.isOnline and not Net.isHost and not isLocal:
		$AudioShieldStart.play()
		return # host owns the duration; visibility/end sound mirror via state sync
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
			_netLabel('0', global_position, Color.WHITE, fallingMessageSize)
		else:
			_netLabel(str(int(actualDamage)), global_position, Color.TOMATO, fallingMessageSize)
			hp -= actualDamage
			if inflictorPlayerId != null && playerId != inflictorPlayerId && Global.playersPerks[inflictorPlayerId].has(Global.PerkEnum.VAMPIRE):
				Global.getPlayer(inflictorPlayerId).heal(actualDamage)
			if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN) && actualDamage > 5:
				emitFeathers(actualDamage)
			$Hurt/Anim.stop()
			$Hurt/Anim.play("hurt")

func heal(amount) -> void:
	if amount > 0 && alive && !Global.playersFrozen:
		_netLabel(str(int(amount)), global_position, Color.LIGHT_GREEN, int(amount / 10) + 1)
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

func fallDown(isLava: bool) -> void:
	if Net.isOnline and isLocal and not Net.isHost and alive and not isFallingIntoWater:
		Net.notify_fall(playerId, isLava)
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
	if isLava:
		$AudioHitBottom.stream = Res.AudioLava
	$AudioHitBottom.play()
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
	lavaAccum = 0.0
	$SmokeParticles.emitting = false

func _integrate_forces(state):
	Global.pacmanWrap(state)
	if onConveyorBelt:
		var beltStep: Vector2 = Global.CONVEYOR_SPEED * state.step
		state.transform.origin += beltStep

func _on_body_entered(body):
	if body.is_in_group('players'):
		if !hit:
			body.hit = true
			if Net.isOnline and not Net.isHost:
				pass # host authors the FX; impulses below stay local
			else:
				var collisionAnim = Res.CollisionAnimObject.instantiate()
				var animScale = (thrust.length() + body.thrust.length()) / 60
				collisionAnim.scale = Vector2(animScale, animScale)
				collisionAnim.position = global_position - ((global_position - body.global_position) / 2)
				collisionAnim.look_at(global_position)
				Global.addToScene(collisionAnim)
				if Net.isOnline:
					Net.collision_fx(collisionAnim.position, animScale, global_position)
		apply_central_impulse(body.global_position.direction_to(global_position) * 50)
		hit = false
	if body.is_in_group('cacti'):
		# Online cactus hits are host-authorized; guests replay via Net.cactus_hit.
		if Net.isOnline and not Net.isHost:
			return
		# todo maybe hurt sound for the non-chicken as well?
		if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
			hurtSound(Res.AudioChickenHurt.pick_random())
		hurt(Global.DAMAGE_CACTUS, null)
		body.bounce()
		body.pinch()
		if Net.isOnline:
			Net.cactus_hit(body.global_position)
		apply_central_impulse(body.global_position.direction_to(global_position) * 100)
	if body.is_in_group('discowalls') and body.has_method('boop'):
		# Nightclub neon ring: bumping the dancefloor edge lights it up.
		# Remote bumps arrive via Net.disco_hit (host authored).
		body.boop()

func isTeammate(otherPlayerId) -> bool:
	return Global.playersTeam[otherPlayerId] == Global.playersTeam[playerId]

func isRighteouslyHitBy(inflictorId) -> bool:
	return alive && !shielded && !isTeammate(inflictorId)

func isJustKilled() -> bool:
	return alive && hp <= 0

func convey() -> void:
	onConveyorBelt = true

func unconvey() -> void:
	onConveyorBelt = false
