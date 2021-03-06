extends Node2D

export var playerId = 0
onready var Lobby = get_node('/root/Lobby')

var inputCd = false

func warningGrowl(message):
	var label = Res.CustomLabel.instance()
	label.position.x = 340
	label.position.y = 220
	label.text = message
	label.fontSize = 2
	label.outline = true
	label.aliveTime = 2
	label.alignment = Label.ALIGN_CENTER
	Lobby.add_child(label)

func _input(event):
	if Global.playersConnected[playerId] && event.device == playerId && !inputCd:
		inputCd = true
		if Input.is_action_just_pressed("ui_accept") and !Lobby.countingDown:
			if !Global.playersJoined[playerId]:
				Global.joinPlayer(playerId, false)
			else:
				if Global.playersJoined.count(true) < 2:
					warningGrowl("NEEDS AT LEAST 2 PLAYERS!")
				elif Global.getNumberOfTeams() < 2:
					warningGrowl("NEEDS AT LEAST 2 TEAMS!")
				else:
					Lobby.startCountdown()
		if Input.is_action_just_pressed("ui_cancel"):
			if Global.playersJoined[playerId]:
				if Lobby.countingDown:
					Lobby.stopCountdown()
				else:
					Global.playersCrowned[playerId] = false
					Global.leavePlayer(playerId)
		if ProjectSettings.get("papope/allow_players_set_options") && !Lobby.countingDown:
			if Input.is_action_just_pressed("pl_nav_up"):
				Global.currentOption = Global.options.keys()[(Global.options.keys().find(Global.currentOption) + (len(Global.options) - 1)) % len(Global.options)]
			if Input.is_action_just_pressed("pl_nav_down"):
				Global.currentOption = Global.options.keys()[(Global.options.keys().find(Global.currentOption) + 1) % len(Global.options)]
			if Input.is_action_just_pressed("pl_nav_left"):
				$AudioOption.play()
				var optionCount = len(Global.options[Global.currentOption])
				Global.optionsSelected[Global.currentOption] = (Global.optionsSelected[Global.currentOption] + (optionCount - 1)) % optionCount
			if Input.is_action_just_pressed("pl_nav_right"):
				$AudioOption.play()
				var optionCount = len(Global.options[Global.currentOption])
				Global.optionsSelected[Global.currentOption] = (Global.optionsSelected[Global.currentOption] + 1) % optionCount
	Lobby.handleLabels()

func handleSpawnSprite():
	if Global.playersConnected[playerId] and !Global.playersJoined[playerId] and !Lobby.countingDown:
		$SpawnSprite.show()
	else:
		$SpawnSprite.hide()

func handleHints():
	$JoinLabel.hide()
	$CancelLabel.hide()
	$LeaveLabel.hide()
	$ControllerSprite.hide()
	
	if Global.playersConnected[playerId]:
		var color = Color.white
		if Global.playersJoined[playerId]:
			color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
			if Lobby.countingDown:
				$CancelLabel.show()
			else:
				$LeaveLabel.show()
		else:
			color.a = 0.5
			if !Lobby.countingDown:
				$JoinLabel.show()
		$ControllerSprite.modulate = color
		$ControllerSprite.show()

func _process(delta):
	inputCd = false
	handleSpawnSprite()
	handleHints()
