extends Node2D

var countdownNode = null
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
		initPlayers()
		Net.lobby_updated.connect(_on_lobby_updated)
	else:
		$MenuCanvas/RoomLabel.hide()
		initPlayers()
	# 'random' backdrop steps align with pan-loop ends so every replay
	# coincides with a sweep boundary on all peers (read, not hardcoded).
	var loopAnim = $MovingBackground/Anim
	if loopAnim != null and loopAnim.has_animation("loop"):
		_bgPeriod = loopAnim.get_animation("loop").length

func _process(delta):
	var hasAnyJoined := Global.playersJoined.has(true)
	$Settings.visible = hasAnyJoined

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
				Net.push_state(Global.getPlayerStates())
			# 'random' background steps on all screens via broadcast, aligned
			# to pan-loop ends (see _bgPeriod).
			if Global.options['map'][Global.optionsSelected['map']] == 'random':
				_bgAccum += delta
				if _bgAccum >= _bgPeriod:
					_bgAccum = 0.0
					advanceBgFrame()
		return
	if !Net.isOnline and !Global.playersJoined.has(true):
		# Last player left: back to the mode select.
		Global.goToMainMenu()
		return
	if Global.playersConnected.count(true) < 2 or Global.playersJoined.count(true) < 2:
		$InitHolder/WaitingLabel.show()
	elif Global.getNumberOfTeams() < 2:
		$InitHolder/TeamLimitLabel.show()
	elif countdownNode == null:
		$InitHolder/StartHolder.show()

func _updateOnlineLabels() -> void:
	$MenuCanvas/RoomLabel.setText("room: " + Net.roomCode)
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
		var focusOwner := get_viewport().gui_get_focus_owner()
		if focusOwner is TextEdit or focusOwner is LineEdit:
			return # typing feedback: keep Esc for the field
		if Net.isOnline:
			Net.leave_to_menu()
		else:
			Global.goToMainMenu()
	if Global.DEBUG && Global.enableHotkeys && !Net.isOnline: 
		if event.is_action_pressed("test1"): 
			for i in range(4):
				if !Global.playersConnected[i]:
					Global.playersConnected[i] = true
					break
				if !Global.playersJoined[i]:
					Global.playersInputMode[i] = Global.InputMode.PAD
					Global.playersDevice[i] = i
					Global.kbClaimable = false
					Global.playersJoined[i] = true
					Global.playersTeam[i] = i
					Global.rollSkin(i)
					Global.joinPlayer(i, false)
					break
		if event.is_action_pressed("test2"): 
			for i in range(4):
				if Global.playersConnected[i]:
					if Global.playersJoined[i]:
						Global.playersJoined[i] = false
						Global.playersInputMode[i] = Global.InputMode.EMPTY
						Global.playersDevice[i] = -1
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
			if Global.playersInputMode[i] == Global.InputMode.EMPTY:
				Global.playersJoined[i] = false
		else:
			if Global.playersConnected[i] && Global.playersJoined[i]:
				Global.joinPlayer(i, true)

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
	Net.send_bg_frame(frame, true)

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

func sendBgTo() -> void:
	# Newcomer paint: explicit maps resolve locally, random takes host's frame.
	if Global.options['map'][Global.optionsSelected['map']] != 'random':
		return
	var bg = get_node_or_null("MovingBackground/Backgrounds")
	if bg == null:
		return
	Net.send_bg_frame(int(bg.frame), true)

func _on_lobby_updated():
	# Reconcile previews with the host's slot flags both ways: joiners appear,
	# leavers disappear. No dedicated removal message needed.
	if !Net.isOnline:
		return
	for i in range(4):
		var preview = Global.getPlayer(i)
		if Global.playersJoined[i] and preview == null:
			Global.joinPlayer(i, true)
		elif not Global.playersJoined[i] and preview != null:
			preview.queue_free()
	# Fixate the background on the host's map selection only; other
	# options (mode/rounds) must not retrigger it. Guests
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
				Net.send_bg_frame(frame, true)
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
	countdownNode = null

func restartMovingBackground() -> void:
	$MovingBackground.restartMovingBackground(null)
