extends Node2D

@export var playerId: int = 0

func handleSpawnSprite():
	if Global.playersConnected[playerId] and !Global.playersJoined[playerId]:
		$SlotSprite.show()
	else:
		$SlotSprite.hide()

func handleHints() -> void:
	$JoinLabel.hide()
	$CancelLabel.hide()
	$LeaveLabel.hide()
	$ControllerSprite.hide()
	
	if Global.playersConnected[playerId]:
		var color = Color.WHITE
		if Global.playersJoined[playerId]:
			color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
		else:
			color.a = 0.5
		$ControllerSprite.modulate = color
		$ControllerSprite.show()

func _process(delta):
	handleSpawnSprite()
	handleHints()

func _input(event):
	if Global.playersConnected[playerId] && event.device == playerId:
		if event.is_action_pressed("accept"):
			if !Global.playersJoined[playerId]:
				Global.joinPlayer(playerId, false)
		if event.is_action_pressed("cancel"):
			if Global.playersJoined[playerId]:
				Global.playersCrowned[playerId] = false
				Global.leavePlayer(playerId)
