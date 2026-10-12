extends Node2D

@onready var _ipEdit = $IpEdit
@onready var _statusLabel = $StatusLabel

func _ready():
	$TitleLabel.setText("online rumble")
	$InfoLabel.setText("your ip: " + Net.get_local_ips() + " - host must open udp " + str(Net.port) + ", or play over zerotier/hamachi")
	$HostButton.pressed.connect(_on_host_pressed)
	$JoinButton.pressed.connect(_on_join_pressed)
	$BackButton.pressed.connect(_on_back_pressed)
	_ipEdit.text_submitted.connect(_on_ip_submitted)
	Net.joined.connect(_on_joined)
	Net.join_failed.connect(_on_join_failed)
	Net.host_left.connect(_on_host_left)

func _exit_tree():
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
	setStatus("opening port...")
	if Net.host():
		setStatus("hosting on " + Net.get_local_ips() + ":" + str(Net.port) + " - share it!")
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _on_join_pressed():
	Net.join(_ipEdit.text)
	setStatus("connecting...")

func _on_ip_submitted(_text):
	_on_join_pressed()

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
