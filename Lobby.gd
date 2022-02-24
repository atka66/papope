extends Node2D

const hintTimer = 6.0

var countingDown = false

func createHintLabel():
	var randomHint = Global.HINT_STRINGS[randi() % Global.HINT_STRINGS.size()]
	for i in randomHint.size():
		var hintLabel = Res.CustomLabel.instance()
		hintLabel.editor_description = "random_hint"
		hintLabel.position.x = 510
		hintLabel.position.y = 128 + (i * 16)
		hintLabel.text = randomHint[i]
		hintLabel.fontSize = 2
		hintLabel.outline = true
		hintLabel.aliveTime = hintTimer
		hintLabel.alignment = Label.ALIGN_CENTER
		add_child(hintLabel)
	yield(get_tree().create_timer(hintTimer), "timeout")

func handleLabels():
	var hasConnected = Global.playersJoined.has(true)
	$TitleHolder.visible = !hasConnected

	$MenuHintLabel.visible = hasConnected
	$MenuMovementHintLabel.visible = hasConnected
	$MenuChangeSkinHintLabel.visible = hasConnected
	$MenuChangeTeamHintLabel.visible = ProjectSettings.get("papope/allow_players_set_options") && hasConnected
	$MenuNagivationHintLabel.visible = ProjectSettings.get("papope/allow_players_set_options") && hasConnected
	$IngameHintLabel.visible = hasConnected
	$IngameMovementHintLabel.visible = hasConnected
	$IngameAimHintLabel.visible = hasConnected
	$IngameDashHintLabel.visible = hasConnected
	$IngameUseHintLabel.visible = hasConnected
	$ModeOption.visible = hasConnected
	$MapOption.visible = hasConnected
	$RoundsOption.visible = hasConnected

	$InitHolder/WaitingLabel.hide()
	$InitHolder/TeamLimitLabel.hide()
	$InitHolder/StartLabel.hide()
	if Global.playersConnected.count(true) < 2 or Global.playersJoined.count(true) < 2:
		$InitHolder/WaitingLabel.show()
	elif Global.getNumberOfTeams() < 2:
		$InitHolder/TeamLimitLabel.show()
	elif !countingDown:
		$InitHolder/StartLabel.show()

func determineBackground():
	var resultFrame = ($MovingBackground.frame + (randi() % ($MovingBackground.vframes - 1)) + 1) % $MovingBackground.vframes
	if Global.playersJoined.has(true):
		match Global.options['map'][Global.optionsSelected['map']]:
			'western':
				resultFrame = 0
			'hell':
				resultFrame = 1
			'ship':
				resultFrame = 2
			'space':
				resultFrame = 3
			'traffic':
				resultFrame = 4
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
	$VersionLabel.set_text('V' + Global.VERSION)
	while true:
		yield(createHintLabel(), "completed")

func _process(delta):
	handleLabels()

func restartMovingBackground(anim_name):
	determineBackground()
	$BackgroundDimAnim.seek(0)
	$BackgroundDimAnim.play('loop')

# DEBUG
func _input(event): 
	if Global.DEBUG && Input.is_action_just_pressed("test"): 
		Global.goToMap()
