extends Node2D

@onready var optionNodes = [$ModeOption, $MapOption, $RoundsOption]

var currentOption = 0

func _ready():
	initOptions()

func _input(event):
	if event.is_action_pressed("nav_down"):
		currentOption = (currentOption + 1) % 3
		updateCurrentOption()
		$AudioTick.play()
	if event.is_action_pressed("nav_up"):
		currentOption = (currentOption + 5) % 3
		updateCurrentOption()
		$AudioTick.play()
	if event.is_action_pressed("nav_right"):
		var option = Global.options.keys()[currentOption]
		Global.optionsSelected[option] = (Global.optionsSelected[option] + 1) % Global.options[option].size()
		updateSelections()
		optionNodes[currentOption].animateArrow(true)
		$AudioTick.play()
	if event.is_action_pressed("nav_left"):
		var option = Global.options.keys()[currentOption]
		Global.optionsSelected[option] = (Global.optionsSelected[option] + ((Global.options[option].size() * 2) - 1)) % Global.options[option].size()
		updateSelections()
		optionNodes[currentOption].animateArrow(false)
		$AudioTick.play()

func initOptions() -> void:
	$ModeOption.setOption('mode')
	$MapOption.setOption('map')
	$RoundsOption.setOption('rounds')
	updateCurrentOption()
	updateSelections()

func updateCurrentOption() -> void:
	$ModeOption.setFocus(currentOption == 0)
	$MapOption.setFocus(currentOption == 1)
	$RoundsOption.setFocus(currentOption == 2)

func updateSelections() -> void:
	$ModeOption.setSelection(Global.options['mode'][Global.optionsSelected['mode']])
	$MapOption.setSelection(Global.options['map'][Global.optionsSelected['map']])
	$RoundsOption.setSelection(str(Global.options['rounds'][Global.optionsSelected['rounds']]))
	
