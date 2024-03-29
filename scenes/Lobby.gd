extends Node2D

var countdownNode = null

func _ready():
	Global.MusicNode.play('menu')
	$MenuCanvas/VersionLabel.setText(Global.VERSION)
	if ProjectSettings.get("papope/hosted_mode"):
		$MenuCanvas/FullscreenLabel.setText('atka66.itch.io/papope')
	initPlayers()

func _process(delta):
	var hasConnected = Global.playersJoined.has(true)
	
	$Settings.visible = hasConnected
	$MenuCanvas/Hints.visible = !ProjectSettings.get("papope/hosted_mode") && hasConnected

	$InitHolder/WaitingLabel.hide()
	$InitHolder/TeamLimitLabel.hide()
	$InitHolder/StartHolder.hide()
	if Global.playersConnected.count(true) < 2 or Global.playersJoined.count(true) < 2:
		$InitHolder/WaitingLabel.show()
	elif Global.getNumberOfTeams() < 2:
		$InitHolder/TeamLimitLabel.show()
	elif countdownNode == null:
		$InitHolder/StartHolder.show()

func _input(event):
	if event.is_action_pressed("quit") and !OS.has_feature("web"):
		get_tree().quit()
	if Global.DEBUG: 
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
	Global.playersAchievements = [[], [], [], []]
	# for debugging purposes
	#Global.playersAchievements = [[Global.AchiEnum.UNDERDOG, Global.AchiEnum.NO_REFUNDS, Global.AchiEnum.GUNSLINGER, Global.AchiEnum.DAREDEVIL, Global.AchiEnum.TRIPLE_KILL], [Global.AchiEnum.TRIPLE_KILL, Global.AchiEnum.TRIPLE_KILL], [], []]
	Global.playersPerks = [[], [], [], []]
	Global.initPlayerStats()
	
	for i in range(4):
		if ProjectSettings.get("papope/hosted_mode"):
			Global.playersJoined[i] = false
		else:
			if Global.playersConnected[i] && Global.playersJoined[i]:
				Global.joinPlayer(i, true)

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
