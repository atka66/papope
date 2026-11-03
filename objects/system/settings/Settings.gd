extends Node2D

@onready var optionNodes = [$ModeOption, $MapOption, $RoundsOption]
@onready var Lobby = get_node('/root/Lobby')

var currentOption = 0

func _ready():
	initOptions()
	for i in range(optionNodes.size()):
		optionNodes[i].focused.connect(_on_option_focused.bind(i))
		optionNodes[i].cycled.connect(_on_option_cycled.bind(i))

func _process(delta):
	if Net.isOnline and not Net.isHost:
		# Guests mirror the host's options (synced via Net.push_lobby):
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
	if Global.enableHotkeys && Lobby.countdownNode == null && Global.playersJoined.has(true):
		if event.is_action_pressed("nav_down"):
			currentOption = (currentOption + 1) % 3
			$AudioTick.play()
		if event.is_action_pressed("nav_up"):
			currentOption = (currentOption + 5) % 3
			$AudioTick.play()
		if event.is_action_pressed("nav_right"):
			_cycleOption(1)
		if event.is_action_pressed("nav_left"):
			_cycleOption(-1)

func _on_option_focused(index: int) -> void:
	if not _canEditOptions():
		return
	currentOption = index
	updateCurrentOption()

func _on_option_cycled(delta: int, index: int) -> void:
	if not _canEditOptions():
		return
	currentOption = index
	_cycleOption(delta)

func _canEditOptions() -> bool:
	return not (Net.isOnline and not Net.isHost) \
		and Lobby.countdownNode == null \
		and Global.playersJoined.has(true)

func _cycleOption(delta: int) -> void:
	var option = Global.options.keys()[currentOption]
	var optionCount: int = Global.options[option].size()
	Global.optionsSelected[option] = posmod(Global.optionsSelected[option] + delta, optionCount)
	updateSelections()
	optionNodes[currentOption].animateArrow(delta > 0)
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
