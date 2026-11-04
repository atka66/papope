extends Node2D

@export var playerId: int = 0
@onready var Lobby = get_node('/root/Lobby')

func handleSpawnSprite():
	var show: bool = Global.playersConnected[playerId] and !Global.playersJoined[playerId]
	if !Net.isOnline and !show and Lobby.countdownNode == null:
		# Availability prompt lives on the lowest-free slot only: any pad
		# press claims exactly that slot (lowest-free-first binding).
		show = Global.lowestFreeSlot() == playerId and Global.playersJoined.count(true) < 4
	$Slot.visible = show

func handleHints() -> void:
	$JoinHolder.hide()
	$CancelHolder.hide()
	$LeaveHolder.hide()
	$ControllerSprite.hide()

	if Net.isOnline:
		# Prompts are per-client: only the local slot's hints are actionable
		# (remote input is ignored), so only it gets any. The prompt itself
		# marks your slot - no extra label needed.
		if Global.playersJoined[playerId]:
			if playerId == Net.localSlot:
				if Lobby.countdownNode != null:
					$CancelHolder.show()
				else:
					$LeaveHolder.show()
		return

	if Global.playersConnected[playerId]:
		# Sheet frame 0 = gamepad, 1 = kb+mouse, 2 = touch. EMPTY means a pad
		# is plugged but unbound (connected-but-not-joined), so it falls back
		# to the pad icon.
		var mode = Global.playersInputMode[playerId]
		if mode == Global.InputMode.KB:
			$ControllerSprite.frame = 1
		elif mode == Global.InputMode.TOUCH:
			$ControllerSprite.frame = 2
		else:
			$ControllerSprite.frame = 0
		var color = Color.WHITE
		if Global.playersJoined[playerId]:
			color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
			if Lobby.countdownNode != null:
				$CancelHolder.show()
			else:
				$LeaveHolder.show()
		else:
			color.a = 0.5
			if Lobby.countdownNode == null:
				$JoinHolder.show()
		$ControllerSprite.modulate = color
		$ControllerSprite.show()
	elif !Net.isOnline and Lobby.countdownNode == null:
		if Global.lowestFreeSlot() == playerId and Global.playersJoined.count(true) < 4:
			$JoinHolder.show()

func _process(delta):
	handleSpawnSprite()
	handleHints()

func _input(event):
	# A touch tap also arrives as an emulated mouse click, and kb_use/kb_dash
	# map to the mouse buttons: those belong to the TouchTargets only, so they
	# must never claim, start, or leave a slot.
	if _isTouchClick(event):
		return
	if Net.isOnline:
		_onlineInput(event)
		return
	# Pad claim: exactly the lowest-free slot answers an unbound pad.
	if Lobby.countdownNode == null and event.is_action_pressed("game_use") and event.device >= 0:
		if not Global.isDeviceBound(event.device) and Global.lowestFreeSlot() == playerId:
			if Global.bindPad(event.device) == playerId:
				Global.joinPlayer(playerId, false)
			return
	if event.device == Global.deviceForPlayer(playerId):
		if event.is_action_pressed("game_use") and Global.playersJoined[playerId]:
			# 'use' toggles the countdown: start when idle, cancel while running.
			if Lobby.countdownNode != null:
				Lobby.stopCountdown()
			elif Global.getNumberOfTeams() > 1:
				Lobby.startCountdown()
			else:
				Lobby.warnCannotStart()
	if playerId == 0:
		# Keyboard is dead once a pad claimed first (kbClaimable flipped).
		if Global.enableHotkeys && event.is_action_pressed("kb_use"):
			if Lobby.countdownNode == null and Global.playersInputMode[0] == Global.InputMode.EMPTY and Global.isKbJoinAllowed():
				Global.bindKbSlot0()
				Global.joinPlayer(0, false)
			elif Global.playersJoined[0] and Global.playersInputMode[0] == Global.InputMode.KB:
				if Lobby.countdownNode != null:
					Lobby.stopCountdown()
				elif Global.getNumberOfTeams() > 1:
					Lobby.startCountdown()
				else:
					Lobby.warnCannotStart()

func _onlineInput(event):
	# Online slots are assigned by the host; each peer drives only their own slot.
	# Device ids are per-machine, so any local pad/keyboard owns the local slot.
	if playerId != Net.localSlot:
		return
	var padUse: bool = event.is_action_pressed("game_use") || (Global.enableHotkeys && event.is_action_pressed("kb_use"))
	if not padUse:
		return
	# 'use' toggles the countdown; only the host can drive it either way.
	if Lobby.countdownNode != null:
		if Net.isHost:
			Net.cancel_countdown()
	elif Global.getNumberOfTeams() > 1:
		if Net.isHost:
			Net.begin_countdown()
	else:
		Lobby.warnCannotStart()

func _isTouchClick(event: InputEvent) -> bool:
	# Touch screens also emit a left click tagged DEVICE_ID_EMULATION, and
	# kb_use/kb_dash are bound to the mouse buttons. On touch devices every
	# mouse event belongs to the overlay, never to a slot action.
	return event is InputEventMouseButton \
		and (Touch.mobile_mode or event.device == InputEvent.DEVICE_ID_EMULATION)
