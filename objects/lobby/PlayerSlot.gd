extends Node2D

@export var playerId: int = 0
@onready var Lobby = get_node('/root/Lobby')

func handleSpawnSprite():
	if Global.playersConnected[playerId] and !Global.playersJoined[playerId]:
		$Slot.show()
	else:
		$Slot.hide()

func handleHints() -> void:
	$JoinLabel.hide()
	$CancelLabel.hide()
	$LeaveLabel.hide()
	$ControllerSprite.hide()
	
	if Global.playersConnected[playerId]:
		var color = Color.WHITE
		if Global.playersJoined[playerId]:
			color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
			if Lobby.countdownNode != null:
				$CancelLabel.show()
			else:
				$LeaveLabel.show()
		else:
			color.a = 0.5
			if Lobby.countdownNode == null:
				$JoinLabel.show()
		$ControllerSprite.modulate = color
		$ControllerSprite.show()

func _process(delta):
	handleSpawnSprite()
	handleHints()

func _input(event):
	if Global.playersConnected[playerId] && event.device == playerId:
		if event.is_action_pressed("accept") and Lobby.countdownNode == null:
			if !Global.playersJoined[playerId]:
				Global.joinPlayer(playerId, false)
			else:
				if Global.playersJoined.count(true) < 1: # TODO rewrite to 1
					# todo growl
					pass
				# todo elif numberofteams
				else:
					Lobby.startCountdown()
		if event.is_action_pressed("cancel"):
			if Global.playersJoined[playerId]:
				if Lobby.countdownNode != null:
					Lobby.stopCountdown()
				else:
					Global.playersCrowned[playerId] = false
					Global.leavePlayer(playerId)
