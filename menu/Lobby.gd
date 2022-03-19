extends Node2D

const hintTimer = 6.0

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
	get_node('/root/Music').play('menu')

	initPlayers()
	
	while true:
		yield(createHintLabel(), "completed")

func _process(delta):
	for i in range(4):
		get_node("PlayerSlot" + str(i)).show()

	var hasConnected = Global.playersJoined.has(true)

	$CanvasLayer/Hints.visible = hasConnected
	$CanvasLayer/MenuChangeTeamHintLabel.visible = ProjectSettings.get("papope/allow_players_set_options") && hasConnected
	$CanvasLayer/MenuNagivationHintLabel.visible = ProjectSettings.get("papope/allow_players_set_options") && hasConnected
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

# DEBUG
func _input(event): 
	if Input.is_action_just_pressed("quit"):
		get_tree().change_scene(Res.MainmenuPath)
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