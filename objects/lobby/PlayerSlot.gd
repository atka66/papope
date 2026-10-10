extends Node2D

@export var playerId: int = 0
@onready var Lobby = get_node('/root/Lobby')

func handleSpawnSprite():
	if Global.playersConnected[playerId] and !Global.playersJoined[playerId]:
		$Slot.show()
	else:
		$Slot.hide()

func handleHints() -> void:
	$JoinHolder.hide()
	$CancelHolder.hide()
	$LeaveHolder.hide()
	$ControllerSprite.hide()
	
	if Global.playersConnected[playerId]:
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

func _process(delta):
	handleSpawnSprite()
	handleHints()

func _input(event):
	if Net.isOnline:
		_onlineInput(event)
		return
	if Global.playersConnected[playerId] && event.device == playerId:
		if event.is_action_pressed("accept") and Lobby.countdownNode == null:
			if !Global.playersJoined[playerId]:
				Global.joinPlayer(playerId, false)
			else:
				if Global.getNumberOfTeams() > 1:
					Lobby.startCountdown()
				else:
					Lobby.warnCannotStart()
		if event.is_action_pressed("cancel"):
			if Global.playersJoined[playerId]:
				if Lobby.countdownNode != null:
					Lobby.stopCountdown()
				else:
					Global.playersCrowned[playerId] = false
					Global.leavePlayer(playerId)
	if playerId == 0:
		if Global.enableHotkeys && event.is_action_pressed("kb_accept") and Lobby.countdownNode == null:
			if !Global.playersConnected[0]:
				Global.connectPlayer(0)
			if !Global.playersJoined[0]:
				Global.joinPlayer(0, false)
			else:
				if Global.getNumberOfTeams() > 1:
					Lobby.startCountdown()
				else:
					Lobby.warnCannotStart()
		if Global.enableHotkeys && event.is_action_pressed("kb_cancel"):
			if Global.playersJoined[0]:
				if Lobby.countdownNode != null:
					Lobby.stopCountdown()
				else:
					Global.playersCrowned[0] = false
					Global.leavePlayer(0)

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
			Global.playersCrowned[playerId] = false
			Net.leave()
			get_tree().change_scene_to_file("res://scenes/OnlineMenu.tscn")
