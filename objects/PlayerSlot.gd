extends Node2D

export var playerId = 0
onready var Lobby = get_node('/root/Lobby')

func warningGrowl(message):
	var label = Global.CustomLabel.instance()
	label.position.x = 340
	label.position.y = 200
	label.text = message
	label.fontSize = 2
	label.outline = true
	label.aliveTime = 2
	label.alignment = Label.ALIGN_CENTER
	Lobby.add_child(label)

#TODO remove
func _input(event):
	if Global.playersConnected[playerId]: # this condition should not be necessary in the future
		if Input.is_key_pressed(Global.MOCKED_CTRL_KEYS[playerId]['x']) and !Lobby.countingDown:
			if !Global.playersJoined[playerId]:
				Lobby.joinPlayer(playerId)
			else:
				if Global.playersJoined.count(true) < 2:
					warningGrowl("NEEDS AT LEAST 2 PLAYERS!")
				elif Global.getNumberOfTeams() < 2:
					warningGrowl("NEEDS AT LEAST 2 TEAMS!")
				else:
					Lobby.countingDown = true
	Lobby.handleLabels()

func handleSpawnSprite():
	if Global.playersConnected[playerId] and !Global.playersJoined[playerId] and !Lobby.countingDown:
		$SpawnSprite.show()
	else:
		$SpawnSprite.hide()

func handleControllerSprite():
	var color = Color.white
	if Global.playersConnected[playerId]:
		if Global.playersJoined[playerId]:
			color = Global.PLAYER_COLORS[playerId]
	else:
		color.a = 0.5
	$ControllerSprite.modulate = color

func handleHints():
	$JoinLabel.hide()
	$CancelLabel.hide()
	$LeaveLabel.hide()
	$OfflineLabel.hide()
	
	if Global.playersConnected[playerId]:
		if Global.playersJoined[playerId]:
			if Lobby.countingDown:
				$CancelLabel.show()
			else:
				$LeaveLabel.show()
		else:
			if !Lobby.countingDown:
				$JoinLabel.show()
	else:
		$OfflineLabel.show()

func _process(delta):
	handleSpawnSprite()
	handleControllerSprite()
	handleHints()
