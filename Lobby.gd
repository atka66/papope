extends Node2D

const hintTimer = 6.0

# menustate helper:
#  0 - local/multi
#  1 - local - lobby
#  2 - multi - host/join
#  3 - multi - lobby
var menuState = 0

var isLocal = true

var countingDown = false

func createHintLabel():
	var randomHint = Global.HINT_STRINGS[randi() % Global.HINT_STRINGS.size()]
	for i in randomHint.size():
		var hintLabel = Res.CustomLabel.instance()
		hintLabel.editor_description = "random_hint"
		hintLabel.position.x = 0
		hintLabel.position.y = i * 16
		hintLabel.text = randomHint[i]
		hintLabel.fontSize = 2
		hintLabel.outline = true
		hintLabel.aliveTime = hintTimer
		hintLabel.alignment = Label.ALIGN_CENTER
		$HintHolder.add_child(hintLabel)
	yield(get_tree().create_timer(hintTimer), "timeout")

func determineBackground():
	var resultFrame = ($MovingBackground.frame + (randi() % ($MovingBackground.frames.get_frame_count('default') - 1)) + 1) % $MovingBackground.frames.get_frame_count('default')
	if Global.playersJoined.has(true):
		match Global.options['map'][Global.optionsSelected['map']]:
			'hell':
				resultFrame = 0
			'western':
				resultFrame = 1
			'ship':
				resultFrame = 2
			'space':
				resultFrame = 3
			'traffic':
				resultFrame = 4
			'pacman':
				resultFrame = 5
			'conveyor':
				resultFrame = 6
	$MovingBackground.frame = resultFrame

func startCountdown():
	countingDown = true
	var countdown = Res.Countdown.instance()
	countdown.position = Vector2(340, 112)
	add_child(countdown)

func stopCountdown():
	countingDown = false
	for cd in get_tree().get_nodes_in_group("countdown"):
		cd.queue_free()

func initPlayers():
	Global.playersFrozen = false
	Global.playersPoints = [0, 0, 0, 0]
	Global.playersAchievements = [[], [], [], []]
	Global.playersPerks = [[], [], [], []]

	for i in range(4):
		if ProjectSettings.get("papope/disconnect_on_init"):
			Global.playersJoined[i] = false
		else:
			if Global.playersConnected[i] && Global.playersJoined[i]:
				Global.joinPlayer(i, true)
	
	Global.playersStats = []
	for i in range(4):
		Global.playersStats.append(
			{
				Global.StatEnum.REV_USE: 0, Global.StatEnum.REV_HIT: 0,
				Global.StatEnum.DYN_USE: 0, Global.StatEnum.DYN_DMG: 0,
				Global.StatEnum.WHP_USE: 0, Global.StatEnum.WHP_HIT: 0,
				Global.StatEnum.TRP_USE: 0, Global.StatEnum.TRP_HIT: 0,
				Global.StatEnum.PELLETS: 0, Global.StatEnum.GHOST_KILL: 0
			}
		)

func _ready():
	get_node('/root/Music').play('lobby')

	initPlayers()

	restartMovingBackground(null)
	$Canvas/VersionLabel.set_text('V' + Global.VERSION)
	while true:
		yield(createHintLabel(), "completed")

func _process(delta):
	if menuState == 0:
		for i in range(4):
			get_node("PlayerSlot" + str(i)).hide()
		$Canvas/Hints.hide()
		$Canvas/MenuChangeTeamHintLabel.hide()
		$Canvas/MenuNagivationHintLabel.hide()
		$Options.hide()
		$InitHolder.hide()
		$HintHolder.hide()
		$GameTypeHolder.show()
	if menuState == 1 || menuState == 3:
		for i in range(4):
			get_node("PlayerSlot" + str(i)).show()

		var hasConnected = Global.playersJoined.has(true)

		$Canvas/Hints.visible = hasConnected
		$Canvas/MenuChangeTeamHintLabel.visible = ProjectSettings.get("papope/allow_players_set_options") && hasConnected
		$Canvas/MenuNagivationHintLabel.visible = ProjectSettings.get("papope/allow_players_set_options") && hasConnected
		$Options.visible = hasConnected

		$InitHolder.show()
		$InitHolder/WaitingLabel.hide()
		$InitHolder/TeamLimitLabel.hide()
		$InitHolder/StartLabel.hide()
		if Global.playersConnected.count(true) < 2 or Global.playersJoined.count(true) < 2:
			$InitHolder/WaitingLabel.show()
		elif Global.getNumberOfTeams() < 2:
			$InitHolder/TeamLimitLabel.show()
		elif !countingDown:
			$InitHolder/StartLabel.show()
		$HintHolder.show()
		$GameTypeHolder.hide()

func restartMovingBackground(anim_name):
	determineBackground()
	$BackgroundDimAnim.seek(0)
	$BackgroundDimAnim.play('loop')

# DEBUG
func _input(event): 
	if menuState == 0:
		if Input.is_action_just_pressed("quit"):
			get_tree().quit()
		if (Input.is_action_just_pressed("pl_nav_down") ||
			Input.is_action_just_pressed("pl_nav_up")):
			isLocal = !isLocal
			if isLocal:
				$GameTypeHolder/Anim.play("wobble_local")
				$GameTypeHolder/OnlineHolder.scale = Vector2.ONE
				$GameTypeHolder/OnlineHolder.rotation_degrees = 0
			if !isLocal:
				$GameTypeHolder/Anim.play("wobble_online")
				$GameTypeHolder/LocalHolder.scale = Vector2.ONE
				$GameTypeHolder/LocalHolder.rotation_degrees = 0
		if Input.is_action_just_pressed("ui_accept"):
			if isLocal:
				menuState = 1
			else:
				#coming soon
				#menuState = 2
				pass
	if menuState == 1:
		if Input.is_action_just_pressed("quit"):
			menuState = 0
			stopCountdown()
			for i in range(4):
				Global.leavePlayer(i)
		if Global.DEBUG: 
			if Input.is_action_just_pressed("test1"): 
				for i in range(4):
					if !Global.playersConnected[i]:
						Global.playersConnected[i] = true
						break
					if !Global.playersJoined[i]:
						Global.playersJoined[i] = true
						Global.joinPlayer(i, false)
						break
			if Input.is_action_just_pressed("test2"): 
				for i in range(4):
					if Global.playersConnected[i]:
						if Global.playersJoined[i]:
							Global.playersJoined[i] = false
							Global.leavePlayer(i)
							break
			if Input.is_action_just_pressed("test3"):
				Global.goToMap()
