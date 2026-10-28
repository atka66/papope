extends Node2D

@export var playerId: int = 0
@onready var Lobby = get_node('/root/Lobby')

var _badgeText := "###"

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
		# marks your slot - no extra label needed. No scheme sprite either:
		# online a slot owns both schemes (last input wins), so there is no
		# per-player scheme to show.
		if Global.playersJoined[playerId]:
			if playerId == Net.localSlot:
				if Lobby.countdownNode != null:
					$CancelHolder.show()
				else:
					$LeaveHolder.show()
		updateSchemeBadge()
		return

	if Global.playersConnected[playerId]:
		# Sheet frame 0 = gamepad, 1 = kb+mouse. EMPTY means a pad is plugged
		# but unbound (connected-but-not-joined), so it falls back to pad.
		$ControllerSprite.frame = 1 if Global.playersInputMode[playerId] == Global.InputMode.KB else 0
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
	updateSchemeBadge()

func updateSchemeBadge() -> void:
	var text := ""
	if not Net.isOnline and Global.playersJoined[playerId]:
		if Global.playersInputMode[playerId] == Global.InputMode.KB:
			text = "kb"
		elif Global.playersInputMode[playerId] == Global.InputMode.PAD:
			text = "pad" + str(Global.playersDevice[playerId])
	if text != _badgeText:
		_badgeText = text
		$SchemeLabel.setText(text)

func _process(delta):
	handleSpawnSprite()
	handleHints()

func _input(event):
	if Net.isOnline:
		_onlineInput(event)
		return
	# Pad claim: exactly the lowest-free slot answers an unbound pad.
	if Lobby.countdownNode == null and event.is_action_pressed("accept") and event.device >= 0:
		if not Global.isDeviceBound(event.device) and Global.lowestFreeSlot() == playerId:
			if Global.bindPad(event.device) == playerId:
				Global.joinPlayer(playerId, false)
			return
	if event.device == Global.deviceForPlayer(playerId):
		if event.is_action_pressed("accept") and Lobby.countdownNode == null:
			if Global.playersJoined[playerId]:
				if Global.getNumberOfTeams() > 1:
					Lobby.startCountdown()
				else:
					Lobby.warnCannotStart()
		if event.is_action_pressed("cancel"):
			if Global.playersJoined[playerId]:
				if Lobby.countdownNode != null:
					Lobby.stopCountdown()
				else:
					Global.clearSlot(playerId)
	if playerId == 0:
		# Keyboard is dead once a pad claimed first (kbClaimable flipped).
		if Global.enableHotkeys && event.is_action_pressed("kb_accept") and Lobby.countdownNode == null:
			if Global.playersInputMode[0] == Global.InputMode.EMPTY and Global.isKbJoinAllowed():
				Global.bindKbSlot0()
				Global.joinPlayer(0, false)
			elif Global.playersJoined[0] and Global.playersInputMode[0] == Global.InputMode.KB:
				if Global.getNumberOfTeams() > 1:
					Lobby.startCountdown()
				else:
					Lobby.warnCannotStart()
		if Global.enableHotkeys && event.is_action_pressed("kb_cancel"):
			if Global.playersJoined[0] and Global.playersInputMode[0] == Global.InputMode.KB:
				if Lobby.countdownNode != null:
					Lobby.stopCountdown()
				else:
					Global.clearSlot(0)

func _onlineInput(event):
	# Online slots are assigned by the host; each peer drives only their own slot.
	# Device ids are per-machine, so any local pad/keyboard owns the local slot.
	if playerId != Net.localSlot:
		return
	var padStart: bool = event.is_action_pressed("accept") || (Global.enableHotkeys && event.is_action_pressed("kb_accept"))
	var padBack: bool = event.is_action_pressed("cancel") || (Global.enableHotkeys && event.is_action_pressed("kb_cancel"))
	if padStart and Lobby.countdownNode == null:
		if Global.getNumberOfTeams() > 1:
			if Net.isHost:
				Net.begin_countdown()
		else:
			Lobby.warnCannotStart()
	if padBack:
		if Lobby.countdownNode != null:
			if Net.isHost:
				Net.cancel_countdown()
		else:
			Net.leave_to_menu()
