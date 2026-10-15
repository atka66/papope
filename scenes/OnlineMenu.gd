extends Node2D

@onready var _codeEdit = $CodeEdit
@onready var _statusLabel = $StatusLabel
@onready var _roomList = $RoomList
@onready var _relayEdit = $RelayEdit

var _roomCodes: Array = []
var _roomLocked: Array = []

func _ready():
	$TitleLabel.setText("online rumble")
	$InfoLabel.setText("relay: " + Net.relay_base())
	$HostButton.pressed.connect(_on_host_pressed)
	$JoinButton.pressed.connect(_on_join_pressed)
	$RefreshButton.pressed.connect(_on_refresh_pressed)
	$BackButton.pressed.connect(_on_back_pressed)
	_codeEdit.text_submitted.connect(_on_code_submitted)
	_roomList.item_selected.connect(_on_room_selected)
	_relayEdit.text = Net.get_user_relay_url()
	_relayEdit.text_submitted.connect(_on_relay_submitted)
	$RelayApplyButton.pressed.connect(_on_relay_apply)
	$RelayResetButton.pressed.connect(_on_relay_reset)
	Net.hosted.connect(_on_hosted)
	Net.joined.connect(_on_joined)
	Net.join_failed.connect(_on_join_failed)
	Net.host_left.connect(_on_host_left)
	_on_refresh_pressed()

func _exit_tree():
	if Net.hosted.is_connected(_on_hosted):
		Net.hosted.disconnect(_on_hosted)
	if Net.joined.is_connected(_on_joined):
		Net.joined.disconnect(_on_joined)
	if Net.join_failed.is_connected(_on_join_failed):
		Net.join_failed.disconnect(_on_join_failed)
	if Net.host_left.is_connected(_on_host_left):
		Net.host_left.disconnect(_on_host_left)

func _input(event):
	if event.is_action_pressed("quit") or event.is_action_pressed("kb_cancel"):
		_on_back_pressed()

func _on_host_pressed():
	setStatus("creating room...")
	Net.host($PrivateCheck.button_pressed)

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
		setStatus("no rooms - host one!")
	else:
		setStatus("%d room(s)" % rooms.size())

func _on_room_selected(index: int):
	if index >= 0 and index < _roomCodes.size():
		_codeEdit.text = _roomCodes[index]

func _on_relay_submitted(_text):
	_on_relay_apply()

func _on_relay_apply():
	var url: String = _relayEdit.text.strip_edges()
	if url.is_empty():
		Net.clear_user_relay_url()
		setStatus("relay reset to default")
	else:
		if not (url.begins_with("ws://") or url.begins_with("wss://")):
			setStatus("url must start with ws:// or wss://")
			return
		Net.set_user_relay_url(url)
		setStatus("relay updated")
	_refreshRelay()

func _on_relay_reset():
	Net.clear_user_relay_url()
	_relayEdit.text = ""
	setStatus("relay reset to default")
	_refreshRelay()

func _refreshRelay():
	$InfoLabel.setText("relay: " + Net.relay_base())
	_on_refresh_pressed()

func _on_back_pressed():
	if Net.isOnline:
		Net.leave()
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_joined():
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_join_failed(reason: String):
	setStatus(reason)

func _on_host_left():
	setStatus("host left")

func setStatus(text: String):
	_statusLabel.setText(text)
