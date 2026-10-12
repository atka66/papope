extends Node2D

@onready var _feedbackAnim = $MenuCanvas/FeedbackHolder/Anim
@onready var _feedbackForm = $MenuCanvas/FeedbackHolder/FeedbackPanel/CenterContainer/VBoxContainer
@onready var _feedbackEdit = $MenuCanvas/FeedbackHolder/FeedbackPanel/CenterContainer/VBoxContainer/FeedbackEdit
@onready var _feedbackFinish = $MenuCanvas/FeedbackHolder/FeedbackPanel/CenterContainer/FinishLabel
@onready var _audioSubmit = $MenuCanvas/FeedbackHolder/AudioSubmit

var countdownNode = null
var hasConnected = true
var _bgFingerprint = []
var _netAccum := 0.0
var _bgAccum := 0.0
var _bgSeed := 0
var _bgStep := 0
var _bgPeriod := 8.0

func _ready():
	Global.MusicNode.play('menu')
	$MenuCanvas/VersionLabel.setText(Global.VERSION)
	if ProjectSettings.get("papope/hosted_mode"):
		$MenuCanvas/FullscreenLabel.setText('atka66.itch.io/papope')
	if Net.isOnline:
		$MenuCanvas/OnlineButton.hide()
		initPlayers()
		Net.lobby_updated.connect(_on_lobby_updated)
	else:
		$MenuCanvas/OnlineLabel.hide()
		initPlayers()
	# 'random' backdrop steps align with pan-loop ends so every replay
	# coincides with a sweep boundary on all peers (read, not hardcoded).
	var loopAnim = $MovingBackground/Anim
	if loopAnim != null and loopAnim.has_animation("loop"):
		_bgPeriod = loopAnim.get_animation("loop").length

func _process(delta):
	var currentHasConnected = Global.playersJoined.has(true)
	if currentHasConnected != hasConnected:
		$MenuCanvas/TitleHolder/Anim.seek(0)
		if currentHasConnected:
			$MenuCanvas/TitleHolder/Anim.play("back")
		else:
			$MenuCanvas/TitleHolder/Anim.play("front")
	
	hasConnected = currentHasConnected
	
	$Settings.visible = hasConnected
	$MenuCanvas/Hints.visible = !ProjectSettings.get("papope/hosted_mode") && hasConnected

	$InitHolder/WaitingLabel.hide()
	$InitHolder/TeamLimitLabel.hide()
	$InitHolder/StartHolder.hide()
	if Net.isOnline:
		_updateOnlineLabels()
		# Host simulates every preview (map-identical authority); guests
		# interpolate the snapshots, so collisions behave like in-map.
		if Net.isHost:
			_netAccum += delta
			if _netAccum >= Net.STATE_RATE:
				_netAccum = 0.0
				Net.push_state.rpc(Global.getPlayerStates())
			# 'random' background steps on all screens via broadcast, aligned
			# to pan-loop ends (see _bgPeriod).
			if Global.options['map'][Global.optionsSelected['map']] == 'random':
				_bgAccum += delta
				if _bgAccum >= _bgPeriod:
					_bgAccum = 0.0
					advanceBgFrame()
		return
	if Global.playersConnected.count(true) < 2 or Global.playersJoined.count(true) < 2:
		$InitHolder/WaitingLabel.show()
	elif Global.getNumberOfTeams() < 2:
		$InitHolder/TeamLimitLabel.show()
	elif countdownNode == null:
		$InitHolder/StartHolder.show()

func _updateOnlineLabels() -> void:
	if Net.isHost:
		$MenuCanvas/OnlineLabel.setText("online - hosting (slot 0)")
	else:
		$MenuCanvas/OnlineLabel.setText("online - player " + str(Net.localSlot))
	if Global.playersJoined.count(true) < 2:
		$InitHolder/WaitingLabel.setText("waiting for more players...")
		$InitHolder/WaitingLabel.show()
	elif Global.getNumberOfTeams() < 2:
		$InitHolder/TeamLimitLabel.show()
	elif Net.isHost and countdownNode == null:
		$InitHolder/StartHolder.show()
	elif not Net.isHost:
		$InitHolder/WaitingLabel.setText("waiting for host...")
		$InitHolder/WaitingLabel.show()

func _input(event):
	if event.is_action_pressed("quit") and !OS.has_feature("web"):
		if Net.isOnline:
			Net.leave()
			get_tree().change_scene_to_file("res://scenes/OnlineMenu.tscn")
		else:
			get_tree().quit()
	if !Net.isOnline and event is InputEventKey and event.pressed and !event.echo:
		if event.physical_keycode == KEY_O and Global.enableHotkeys:
			get_tree().change_scene_to_file("res://scenes/OnlineMenu.tscn")
	if Global.DEBUG && Global.enableHotkeys && !Net.isOnline: 
		if event.is_action_pressed("test1"): 
			for i in range(4):
				if !Global.playersConnected[i]:
					Global.playersConnected[i] = true
					break
				if !Global.playersJoined[i]:
					Global.playersJoined[i] = true
					Global.joinPlayer(i, false)
					break
		if event.is_action_pressed("test2"): 
			for i in range(4):
				if Global.playersConnected[i]:
					if Global.playersJoined[i]:
						Global.playersJoined[i] = false
						Global.leavePlayer(i)
						break
		if event.is_action_pressed("test3"):
			Global.goToMap()

func initPlayers() -> void:
	Global.playersFrozen = false
	Global.playersPoints = [0, 0, 0, 0]
	Global.matchSeed = 123
	Global.playersAchievements = [[], [], [], []]
	# for debugging purposes
	#Global.playersAchievements = [[Global.AchiEnum.UNDERDOG, Global.AchiEnum.NO_REFUNDS, Global.AchiEnum.GUNSLINGER, Global.AchiEnum.DAREDEVIL, Global.AchiEnum.TRIPLE_KILL], [Global.AchiEnum.TRIPLE_KILL, Global.AchiEnum.TRIPLE_KILL], [], []]
	Global.playersPerks = [[], [], [], []]
	Global.initPlayerStats()

	if Net.isOnline:
		for i in range(4):
			if Global.playersJoined[i]:
				Global.joinPlayer(i, true)
		return
	for i in range(4):
		if ProjectSettings.get("papope/hosted_mode"):
			Global.playersJoined[i] = false
		else:
			if Global.playersConnected[i] && Global.playersJoined[i]:
				Global.joinPlayer(i, true)

func _on_online_button_pressed():
	get_tree().change_scene_to_file("res://scenes/OnlineMenu.tscn")

func advanceBgFrame() -> void:
	# Host-side 'random' rotation: deterministic seeded order shared by all.
	if !Net.isOnline or !Net.isHost:
		return
	var bg = get_node_or_null("MovingBackground/Backgrounds")
	if bg == null:
		return
	var frameCount: int = bg.sprite_frames.get_frame_count('default')
	_bgStep += 1
	var frame := (_bgSeed + _bgStep) % frameCount
	# Full replay (frame + pan restart) like a selection change: keeps the
	# pan phase aligned on all peers instead of drifting per load time.
	applyBgFrame(frame, true)
	Net.bg_frame.rpc(frame, true)

func applyBgFrame(frame: int, replay: bool) -> void:
	var bg = get_node_or_null("MovingBackground/Backgrounds")
	if bg == null:
		return
	var frameCount: int = bg.sprite_frames.get_frame_count('default')
	bg.frame = frame % frameCount
	if replay:
		var anim = get_node_or_null("MovingBackground/Anim")
		if anim != null:
			anim.seek(0)
			anim.play("loop")

func sendBgTo(peerId: int) -> void:
	# Newcomer paint: explicit maps resolve locally, random takes host's frame.
	if Global.options['map'][Global.optionsSelected['map']] != 'random':
		return
	var bg = get_node_or_null("MovingBackground/Backgrounds")
	if bg == null:
		return
	Net.bg_frame.rpc_id(peerId, int(bg.frame), true)

func _on_lobby_updated():
	# Spawn previews for peers that joined after we entered the lobby.
	if !Net.isOnline:
		return
	for i in range(4):
		if Global.playersJoined[i] and Global.getPlayer(i) == null:
			Global.joinPlayer(i, true)
	# Fixate the background on the host's map selection only; other
	# options (mode/rounds/teams/skins) must not retrigger it. Guests
	# resolve explicit maps locally; 'random' follows host broadcasts.
	var fingerprint = [Global.optionsSelected['map']]
	if fingerprint != _bgFingerprint:
		_bgFingerprint = fingerprint
		var mapName = Global.options['map'][Global.optionsSelected['map']]
		if Net.isHost and mapName == 'random':
			_bgSeed = randi()
			_bgStep = 0
			_bgAccum = 0.0
			var bg = get_node_or_null("MovingBackground/Backgrounds")
			if bg != null:
				var frameCount: int = bg.sprite_frames.get_frame_count('default')
				var frame := _bgSeed % frameCount
				applyBgFrame(frame, true)
				Net.bg_frame.rpc(frame, true)
		elif mapName != 'random' or !Net.isOnline:
			restartMovingBackground()
		# else: online guest with 'random' waits for the host's bg_frame.

func warnCannotStart() -> void:
	$InitHolder/Anim.stop()
	$InitHolder/Anim.play('warn')
	$InitHolder/AudioFail.play()

func startCountdown() -> void:
	var countdown = Res.CountdownObject.instantiate()
	countdown.position = Vector2(680, 256)
	$MenuCanvas.add_child(countdown)
	countdownNode = countdown

func stopCountdown() -> void:
	countdownNode.queue_free()

func restartMovingBackground() -> void:
	$MovingBackground.restartMovingBackground(null)

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
	if _feedbackEdit.text.length() < 1:
		return

	var explosion = Res.ExplosionAnimObject.instantiate()
	explosion.position = $Camera.offset + get_viewport().get_mouse_position()
	explosion.harmful = false
	explosion.shakePwr = 30
	Global.addToScene(explosion)

	feedbackToggle(false)
	submitFeedback(_feedbackEdit.text)

func submitFeedback(feedback: String):
	var request = HTTPRequest.new()
	add_child(request)
	var body = JSON.stringify({ 'feedback': feedback, 'source': 'PAPOPE' })
	request.request(Global.FEEDBACK_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	var response = await request.request_completed
	request.queue_free()


func _on_feedback_edit_focus_entered():
	Global.enableHotkeys = false

func _on_feedback_edit_focus_exited():
	Global.enableHotkeys = true
