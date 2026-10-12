extends Node2D

@onready var optionNodes = [$ModeOption, $MapOption, $RoundsOption]
@onready var Lobby = get_node('/root/Lobby')

var currentOption = 0

func _ready():
	initOptions()

func _process(delta):
	if Net.isOnline and not Net.isHost:
		# Guests mirror the host's options (synced via Net.sync_lobby):
		# values visible, but no selection arrows since they can't change them.
		updateSelections()
		$ModeOption.setFocus(false)
		$MapOption.setFocus(false)
		$RoundsOption.setFocus(false)
		return
	if Lobby.countdownNode != null:
		$ModeOption.setFocus(false)
		$MapOption.setFocus(false)
		$RoundsOption.setFocus(false)
	else:
		updateCurrentOption()

func _input(event):
	if Net.isOnline and not Net.isHost:
		return
	if Global.enableHotkeys && Lobby.countdownNode == null && Global.playersJoined.has(true) && !ProjectSettings.get("papope/hosted_mode"):
		if event.is_action_pressed("nav_down"):
			currentOption = (currentOption + 1) % 3
			$AudioTick.play()
		if event.is_action_pressed("nav_up"):
			currentOption = (currentOption + 5) % 3
			$AudioTick.play()
		if event.is_action_pressed("nav_right"):
			var option = Global.options.keys()[currentOption]
			Global.optionsSelected[option] = (Global.optionsSelected[option] + 1) % Global.options[option].size()
			updateSelections()
			optionNodes[currentOption].animateArrow(true)
			$AudioTick.play()
			if currentOption == 1:
				Lobby.restartMovingBackground()
			Net.push_lobby()
		if event.is_action_pressed("nav_left"):
			var option = Global.options.keys()[currentOption]
			Global.optionsSelected[option] = (Global.optionsSelected[option] + ((Global.options[option].size() * 2) - 1)) % Global.options[option].size()
			updateSelections()
			optionNodes[currentOption].animateArrow(false)
			$AudioTick.play()
			if currentOption == 1:
				Lobby.restartMovingBackground()
			Net.push_lobby()

func initOptions() -> void:
	$ModeOption.setOption('mode')
	$MapOption.setOption('map')
	$RoundsOption.setOption('rounds')
	updateSelections()

func updateCurrentOption() -> void:
	$ModeOption.setFocus(currentOption == 0)
	$MapOption.setFocus(currentOption == 1)
	$RoundsOption.setFocus(currentOption == 2)

func updateSelections() -> void:
	var selectedMode = Global.options['mode'][Global.optionsSelected['mode']]
	$ModeOption.setSelection(selectedMode)
	$ModeInfoLabel1.setText(Global.optionInfo[selectedMode][0])
	$ModeInfoLabel2.setText(Global.optionInfo[selectedMode][1])

	$MapOption.setSelection(Global.options['map'][Global.optionsSelected['map']])

	var rounds = Global.options['rounds'][Global.optionsSelected['rounds']]
	$RoundsOption.setSelection(str(rounds) + ' win' + ('s' if rounds > 1 else ''))
