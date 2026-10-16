extends Node2D

# Pre-lobby mode select: same backdrop/title language as the lobby, two
# choices. The initiating input locks the first offline slot (KB via
# kb_accept/click, PAD via accept on that device, lowest-free-first).
# ONLINE binds nothing: the relay assigns the slot on welcome.

var currentOption := 0 # 0 = local, 1 = online

const SELECTED_COLOR := Color(1.0, 0.752941, 0.12549)

func _ready():
	if Net.isOnline:
		Net.leave()
	Global.clearMenuState()
	Global.MusicNode.play('menu')
	$MenuCanvas/VersionLabel.setText(Global.VERSION)
	if ProjectSettings.get("papope/hosted_mode"):
		$MenuCanvas/FullscreenLabel.setText('atka66.itch.io/papope')
	$MovingBackground.restartMovingBackground(null)
	updateSelection()

func _input(event):
	if event.is_action_pressed("quit") and !OS.has_feature("web"):
		get_tree().quit()
		return
	if event.is_action_pressed("nav_up") or event.is_action_pressed("nav_down"):
		currentOption = 1 - currentOption
		$AudioTick.play()
		updateSelection()
		return
	if event.is_action_pressed("kb_accept"):
		chooseKb()
		return
	if event.is_action_pressed("accept") and event.device >= 0:
		choosePad(event.device)
		return

func updateSelection():
	$MenuCanvas/LocalButton.add_theme_color_override("font_color", SELECTED_COLOR if currentOption == 0 else Color.WHITE)
	$MenuCanvas/OnlineButton.add_theme_color_override("font_color", SELECTED_COLOR if currentOption == 1 else Color.WHITE)
	$MenuCanvas/LocalButton.text = ("> " if currentOption == 0 else "") + "LOCAL RUMBLE"
	$MenuCanvas/OnlineButton.text = ("> " if currentOption == 1 else "") + "ONLINE RUMBLE"

func chooseKb():
	if currentOption == 0:
		if Global.bindKbSlot0():
			get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
		else:
			$AudioFail.play()
	else:
		get_tree().change_scene_to_file("res://scenes/OnlineMenu.tscn")

func choosePad(device: int):
	if currentOption == 0:
		if Global.bindPad(device) >= 0:
			get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
		else:
			$AudioFail.play()
	else:
		get_tree().change_scene_to_file("res://scenes/OnlineMenu.tscn")

func _on_local_button_pressed():
	# Mouse clicks count as keyboard scheme.
	currentOption = 0
	updateSelection()
	chooseKb()

func _on_online_button_pressed():
	currentOption = 1
	updateSelection()
	chooseKb()

func _on_local_mouse_entered():
	currentOption = 0
	updateSelection()

func _on_online_mouse_entered():
	currentOption = 1
	updateSelection()
