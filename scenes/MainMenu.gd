extends Node2D

# Mode select + online panel in one scene. MAIN chooses local/online (the
# initiating input locks the first offline slot); ONLINE is the room panel
# (host/room list/join), entered without binding anything - the relay
# assigns the slot on welcome.

enum MenuState { MAIN, ONLINE }
var menuState := MenuState.MAIN
var currentOption := 0 # 0 = local, 1 = online

# Focus reads brighter (white) while the rest of the choices stay gold.
const FOCUS_COLOR := Color.WHITE
const IDLE_COLOR := Color(1.0, 0.752941, 0.12549)
const SUMMARIES := ["play together on one screen", "play with others across the net"]

var _roomCodes: Array = []
var _roomLocked: Array = []
var _statusText := ""
var _infoText := ""
var onlineAction := 0 # 0 = host, 1 = join
var isPrivate := false
var onlineRow := 0

@onready var _mainHolder = $MenuCanvas/MainHolder
@onready var _onlineHolder = $MenuCanvas/OnlineHolder
@onready var _subtitleLabel = $MenuCanvas/TitleHolder/SubtitleLabel
@onready var _titleAnim = $MenuCanvas/TitleHolder/Anim
@onready var _localLabel = $MenuCanvas/MainHolder/LocalLabel
@onready var _onlineLabel = $MenuCanvas/MainHolder/OnlineLabel
@onready var _selectArrow = $MenuCanvas/MainHolder/SelectArrow
@onready var _codeEdit = $MenuCanvas/OnlineHolder/CodeEdit
@onready var _feedbackAnim = $MenuCanvas/FeedbackHolder/Anim
@onready var _feedbackForm = $MenuCanvas/FeedbackHolder/FeedbackPanel/CenterContainer/VBoxContainer
@onready var _feedbackEdit = $MenuCanvas/FeedbackHolder/FeedbackPanel/CenterContainer/VBoxContainer/FeedbackEdit
@onready var _feedbackFinish = $MenuCanvas/FeedbackHolder/FeedbackPanel/CenterContainer/FinishLabel
@onready var _audioSubmit = $MenuCanvas/FeedbackHolder/AudioSubmit
@onready var _roomList = $MenuCanvas/OnlineHolder/RoomList
@onready var _actionOption = $MenuCanvas/OnlineHolder/ActionOption
@onready var _visibilityOption = $MenuCanvas/OnlineHolder/VisibilityOption
@onready var _hostActionLabel = $MenuCanvas/OnlineHolder/HostActionLabel
@onready var _actionArrow = $MenuCanvas/OnlineHolder/ActionArrow
@onready var _refreshLabel = $MenuCanvas/OnlineHolder/RefreshLabel
@onready var _joinLabel = $MenuCanvas/OnlineHolder/JoinLabel
@onready var _infoLine = $MenuCanvas/OnlineHolder/InfoLine

func _ready():
	if Net.isOnline:
		Net.leave()
	Global.clearMenuState()
	Global.MusicNode.play('menu')
	$MenuCanvas/VersionLabel.setText(Global.VERSION)
	if ProjectSettings.get("papope/hosted_mode"):
		$MenuCanvas/FullscreenLabel.setText('atka66.itch.io/papope')
	$MovingBackground.restartMovingBackground(null)
	_codeEdit.text_submitted.connect(_on_code_submitted)
	_roomList.item_selected.connect(_on_room_selected)
	Net.hosted.connect(_on_hosted)
	Net.joined.connect(_on_joined)
	Net.join_failed.connect(_on_join_failed)
	_actionOption.setOption('action')
	_visibilityOption.setOption('visibility')
	_showMain()
	if Global.sessionNotice != "":
		# Kicked out of an online session: say why where the mode summary sits.
		$MenuCanvas/MainHolder/SummaryLabel.setText(Global.sessionNotice)
		Global.sessionNotice = ""
	_on_refresh_pressed()

func _exit_tree():
	if Net.hosted.is_connected(_on_hosted):
		Net.hosted.disconnect(_on_hosted)
	if Net.joined.is_connected(_on_joined):
		Net.joined.disconnect(_on_joined)
	if Net.join_failed.is_connected(_on_join_failed):
		Net.join_failed.disconnect(_on_join_failed)

func _showMain():
	menuState = MenuState.MAIN
	_onlineHolder.hide()
	_mainHolder.show()
	_subtitleLabel.setText("twin stick arena")
	updateSelection()
	_titleAnim.seek(0)
	_titleAnim.play("front")

func _showOnline():
	menuState = MenuState.ONLINE
	_mainHolder.hide()
	_onlineHolder.show()
	_subtitleLabel.setText("online rumble")
	_titleAnim.seek(0)
	_titleAnim.play("back")
	onlineAction = 0
	isPrivate = false
	onlineRow = 0
	setStatus("")
	_layoutOnline()

func _input(event):
	if menuState == MenuState.ONLINE:
		_onlineInput(event)
		return
	if event.is_action_pressed("quit") and !OS.has_feature("web"):
		var focusOwner := get_viewport().gui_get_focus_owner()
		if focusOwner is TextEdit or focusOwner is LineEdit:
			return # typing feedback: keep Esc for the field
		get_tree().quit()
		return
	if Global.enableHotkeys and (event.is_action_pressed("nav_up") or event.is_action_pressed("nav_down")):
		currentOption = 1 - currentOption
		$AudioTick.play()
		updateSelection()
		return
	if Global.enableHotkeys and event.is_action_pressed("kb_accept"):
		chooseKb()
		return
	if event.is_action_pressed("accept") and event.device >= 0:
		choosePad(event.device)
		return

func _onlineInput(event):
	if event.is_action_pressed("quit") or event.is_action_pressed("kb_cancel"):
		if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit:
			return # editing a field: keep Esc/Backspace for the field
		_on_back_pressed()
		return
	# Gamepad menu control: toggle rows behave like lobby settings (up/down
	# moves the cursor, left/right flips values, accept confirms), while the
	# join controls keep native behavior (list browsing, caret, presses).
	# LineEdits stay keyboard-only for input.
	if event.is_action_pressed("cancel"):
		var focus := get_viewport().gui_get_focus_owner()
		if focus is LineEdit or focus is TextEdit:
			get_viewport().gui_release_focus()
			onlineRow = 0
			_applyOnlineCursor()
		else:
			_on_back_pressed()
		return
	if event.is_action_pressed("nav_up"):
		_onlineNav(-1, true)
		return
	if event.is_action_pressed("nav_down"):
		_onlineNav(1, true)
		return
	if event.is_action_pressed("nav_left"):
		_onlineNav(-1, false)
		return
	if event.is_action_pressed("nav_right"):
		_onlineNav(1, false)
		return
	if event.is_action_pressed("accept") or (Global.enableHotkeys and event.is_action_pressed("kb_accept")):
		_onlineAccept()
		return

func _onlineTargets() -> Array:
	if onlineAction == 0:
		return ["action", "visibility", "hostaction"]
	return ["action", "roomlist", "refresh", "codeedit", "joinbutton"]

func _onlineControl(target: String) -> Control:
	match target:
		"roomlist":
			return _roomList
		"codeedit":
			return _codeEdit
	return null

func _applyOnlineCursor():
	var targets := _onlineTargets()
	onlineRow = posmod(onlineRow, targets.size())
	var target: String = targets[onlineRow]
	_actionOption.setFocus(target == "action")
	_visibilityOption.setFocus(target == "visibility")
	_hostActionLabel.setFontColor(FOCUS_COLOR if target == "hostaction" else IDLE_COLOR)
	_refreshLabel.setFontColor(FOCUS_COLOR if target == "refresh" else IDLE_COLOR)
	_joinLabel.setFontColor(FOCUS_COLOR if target == "joinbutton" else IDLE_COLOR)
	match target:
		"hostaction":
			_showActionArrow(400.0)
		"refresh":
			_showActionArrow(484.0)
		"joinbutton":
			_showActionArrow(588.0)
		_:
			_actionArrow.hide()
	var ctl := _onlineControl(target)
	if ctl != null:
		ctl.grab_focus()
	else:
		get_viewport().gui_release_focus()

func _showActionArrow(y: float):
	_actionArrow.position.y = y
	_actionArrow.show()

func _onlineNav(delta: int, vertical: bool) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus is TextEdit:
		return # multiline caret movement
	if focus is LineEdit and not vertical:
		return # caret movement
	if focus is ItemList and vertical and _roomCodes.size() > 0:
		return # native list browsing
	if not vertical and focus == null:
		# Cursor sits on a custom row (no Control focused): flip its value.
		var target: String = _onlineTargets()[onlineRow]
		if target == "action":
			_flipOnlineAction(delta > 0)
			get_viewport().set_input_as_handled()
			return
		if target == "visibility":
			_flipOnlinePrivate(delta > 0)
			get_viewport().set_input_as_handled()
			return
	onlineRow = posmod(onlineRow + delta, _onlineTargets().size())
	$AudioTick.play()
	_applyOnlineCursor()
	get_viewport().set_input_as_handled()

func _onlineAccept() -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return # native submit handles it
	if focus is ItemList:
		_joinSelectedRoom()
		get_viewport().set_input_as_handled()
		return
	var target: String = _onlineTargets()[onlineRow]
	match target:
		"action":
			_flipOnlineAction(true)
		"visibility":
			_flipOnlinePrivate(true)
		"hostaction":
			_on_host_pressed()
		"refresh":
			_on_refresh_pressed()
		"roomlist":
			_joinSelectedRoom()
		"joinbutton":
			_on_join_pressed()

func _flipOnlineAction(right: bool):
	onlineAction = 1 - onlineAction
	onlineRow = 0
	_actionOption.setSelection("join" if onlineAction == 1 else "host")
	_actionOption.animateArrow(right)
	$AudioTick.play()
	_layoutOnline()
	if onlineAction == 1:
		_on_refresh_pressed()

func _flipOnlinePrivate(right: bool):
	isPrivate = not isPrivate
	_visibilityOption.setSelection("private" if isPrivate else "public")
	_visibilityOption.animateArrow(right)
	$AudioTick.play()
	_updateOnlineInfo()

func _layoutOnline():
	var hosting := onlineAction == 0
	_visibilityOption.visible = hosting
	_hostActionLabel.visible = hosting
	_refreshLabel.visible = not hosting
	_joinLabel.visible = not hosting
	_roomList.visible = not hosting
	_codeEdit.visible = not hosting
	_actionOption.setSelection("host" if hosting else "join")
	_visibilityOption.setSelection("private" if isPrivate else "public")
	_updateOnlineInfo()
	_applyOnlineCursor()

func _updateOnlineInfo():
	if onlineAction == 0:
		_infoText = "hidden - share the code" if isPrivate else "listed - anyone can join"
	_renderInfoLine()

func _renderInfoLine():
	_infoLine.setText(_statusText if _statusText != "" else _infoText)

func updateSelection():
	_localLabel.setFontColor(FOCUS_COLOR if currentOption == 0 else IDLE_COLOR)
	_onlineLabel.setFontColor(FOCUS_COLOR if currentOption == 1 else IDLE_COLOR)
	_selectArrow.position.y = 428.0 if currentOption == 0 else 518.0
	$MenuCanvas/MainHolder/SummaryLabel.setText(SUMMARIES[currentOption])

func chooseKb():
	if currentOption == 0:
		if Global.bindKbSlot0():
			get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
		else:
			$AudioFail.play()
	else:
		_showOnline()

func choosePad(device: int):
	if currentOption == 0:
		if Global.bindPad(device) >= 0:
			get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
		else:
			$AudioFail.play()
	else:
		_showOnline()

func _on_host_pressed():
	setStatus("creating room...")
	Net.host(isPrivate)

func _on_hosted():
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_join_pressed():
	var code: String = _codeEdit.text.strip_edges().to_upper()
	for i in range(_roomCodes.size()):
		if _roomCodes[i] == code and i < _roomLocked.size() and bool(_roomLocked[i]):
			setStatus("match in progress")
			return
	Net.join(_codeEdit.text)
	setStatus("connecting...")

func _on_code_submitted(_text):
	_on_join_pressed()

func _on_refresh_pressed():
	setStatus("fetching rooms...")
	if onlineAction == 1:
		_infoText = ""
		_renderInfoLine()
	var rooms := await Net.rest_list_rooms()
	if not is_instance_valid(_roomList):
		return
	_roomList.clear()
	_roomCodes.clear()
	_roomLocked.clear()
	for r in rooms:
		if r is Dictionary:
			if int(r.get("players", 0)) <= 0:
				continue # orphaned listing, unjoinable
			var locked := bool(r.get("locked", false))
			_roomCodes.append(str(r.get("code", "?")))
			_roomLocked.append(locked)
			var label := "%s (%d/4)" % [str(r.get("code", "?")), int(r.get("players", 0))]
			if locked:
				label += " [IN MATCH]"
			_roomList.add_item(label)
	if rooms.is_empty():
		_infoText = "no rooms - host one!"
	else:
		_infoText = "%d room(s)" % rooms.size()
	setStatus("")

func _joinSelectedRoom():
	var sel: PackedInt32Array = _roomList.get_selected_items()
	if not sel.is_empty() and sel[0] >= 0 and sel[0] < _roomCodes.size():
		_codeEdit.text = _roomCodes[sel[0]]
		_on_join_pressed()
	elif _roomCodes.size() > 0:
		_roomList.select(0)
		_codeEdit.text = _roomCodes[0]
		_on_join_pressed()

func _on_room_selected(index: int):
	if index >= 0 and index < _roomCodes.size():
		_codeEdit.text = _roomCodes[index]

func _on_back_pressed():
	_showMain()

func _on_joined():
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_join_failed(reason: String):
	setStatus(reason)

func setStatus(text: String):
	_statusText = text
	_renderInfoLine()

func _on_feedback_button_toggled(toggled_on):
	if toggled_on:
		_feedbackEdit.text = ""
		feedbackToggle(true)
		_feedbackAnim.play("appear")
	else:
		_feedbackAnim.play_backwards("appear")

func feedbackToggle(toggled_on: bool):
	_feedbackForm.visible = toggled_on
	_feedbackFinish.visible = !toggled_on


func _on_submit_button_pressed():
	var feedback: String = _feedbackEdit.text.strip_edges()
	if feedback.length() < 1:
		return

	var explosion = Res.ExplosionAnimObject.instantiate()
	explosion.position = $Camera.offset + get_viewport().get_mouse_position()
	explosion.harmful = false
	explosion.shakePwr = 30
	Global.addToScene(explosion)

	# Fire-and-forget: thank the player immediately and never block the menu on
	# the network. A failed send is only a log line, not a UI state.
	feedbackToggle(false)
	submitFeedback(feedback)

func submitFeedback(feedback: String) -> void:
	var request := HTTPRequest.new()
	request.timeout = 10.0
	add_child(request)
	var body := JSON.stringify({
		'feedback': feedback.substr(0, 1800),
		'source': 'PAPOPE',
		'version': str(Global.VERSION),
		'platform': OS.get_name()
	})
	if request.request(Net.feedback_url(), ["Content-Type: application/json"], HTTPClient.METHOD_POST, body) != OK:
		push_warning("feedback: request could not start")
		request.queue_free()
		return
	var completed: Array = await request.request_completed
	request.queue_free()
	if int(completed[0]) != HTTPRequest.RESULT_SUCCESS:
		push_warning("feedback: send failed (result %d)" % int(completed[0]))
		return
	var code := int(completed[1])
	if code < 200 or code >= 300:
		push_warning("feedback: relay answered %d" % code)


func _on_feedback_edit_focus_entered():
	Global.enableHotkeys = false

func _on_feedback_edit_focus_exited():
	Global.enableHotkeys = true
