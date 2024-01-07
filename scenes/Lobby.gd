extends Node2D

var countdownNode = null

func _ready():
	Global.MusicNode.play('menu')
	$MenuCanvas/VersionLabel.setText(Global.VERSION)
	initPlayers()

func _process(delta):
	var hasConnected = Global.playersJoined.has(true)
	
	$HintSpawner.visible = hasConnected
	$Settings.visible = hasConnected

	$InitHolder/WaitingLabel.hide()
	$InitHolder/TeamLimitLabel.hide()
	$InitHolder/StartLabel.hide()
	if Global.playersConnected.count(true) < 2 or Global.playersJoined.count(true) < 2:
		$InitHolder/WaitingLabel.show()
	elif Global.getNumberOfTeams() < 2:
		$InitHolder/TeamLimitLabel.show()
	elif countdownNode == null:
		$InitHolder/StartLabel.show()

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
	#Global.playersAchievements = [[Global.AchiEnum.UNDERDOG, Global.AchiEnum.JATSZUNK_MAST, Global.AchiEnum.NO_REFUNDS, Global.AchiEnum.GUNSLINGER, Global.AchiEnum.DAREDEVIL, Global.AchiEnum.TRIPLE_KILL, Global.AchiEnum.JATSZUNK_MAST], [Global.AchiEnum.TRIPLE_KILL, Global.AchiEnum.TRIPLE_KILL], [], []]
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

func startCountdown() -> void:
	var countdown = Res.CountdownObject.instantiate()
	countdown.position = Vector2(340, 112)
	add_child(countdown)
	countdownNode = countdown

func stopCountdown() -> void:
	countdownNode.queue_free()
