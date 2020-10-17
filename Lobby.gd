extends Node2D

const hintTimer = 6.0

# background
var dim = 1.0
var appearing = true

var countingDown = false

func createHintLabel():
	var randomHint = Global.HINT_STRINGS[randi() % Global.HINT_STRINGS.size()]
	for i in randomHint.size():
		var hintLabel = Global.CustomLabel.instance()
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
	var hasConnected = Global.playersConnected.has(true)
	$PapopeLabel.visible = !hasConnected
	$SubtitleLabel.visible = !hasConnected

	$MenuHintLabel.visible = hasConnected
	$MenuMovementHintLabel.visible = hasConnected
	$MenuChangeSkinHintLabel.visible = hasConnected
	$MenuChangeTeamHintLabel.visible = hasConnected
	##TODO depend on setting
	$MenuNagivationHintLabel.visible = hasConnected
	$IngameHintLabel.visible = hasConnected
	$IngameMovementHintLabel.visible = hasConnected
	$IngameAimHintLabel.visible = hasConnected
	$IngameDashHintLabel.visible = hasConnected
	$IngameUseHintLabel.visible = hasConnected

	$WaitingLabel.hide()
	$TeamLimitLabel.hide()
	$StartLabel.hide()
	if Global.playersConnected.count(true) < 2 or Global.playersJoined.count(true) < 2:
		$WaitingLabel.show()
	elif Global.getNumberOfTeams() < 2:
		$TeamLimitLabel.show()
	else:
		$StartLabel.show()

func joinPlayer(playerId):
	Global.playersJoined[playerId] = true
	var slot = get_node('PlayerSlot' + String(playerId))
	var player = Global.Player.instance()
	slot.add_child(player)

func connectPlayer(playerId):
	Global.playersConnected[playerId] = true
	handleLabels()

func disconnectPlayer(playerId):
	Global.playersJoined[playerId] = false
	Global.playersConnected[playerId] = false
	handleLabels()

func _ready():
	handleLabels()
	$VersionLabel.set_text('V' + Global.VERSION)
	while true:
		yield(createHintLabel(), "completed")

func _input(event):
	if Input.is_key_pressed(KEY_0):
		if !Global.playersConnected[0]: connectPlayer(0)
		else: disconnectPlayer(0)
	if Input.is_key_pressed(KEY_1):
		if !Global.playersConnected[1]: connectPlayer(1)
		else: disconnectPlayer(1)
	if Input.is_key_pressed(KEY_2):
		if !Global.playersConnected[2]: connectPlayer(2)
		else: disconnectPlayer(2)
	if Input.is_key_pressed(KEY_3):
		if !Global.playersConnected[3]: connectPlayer(3)
		else: disconnectPlayer(3)

func handleBackground():
	$MovingBackground.position.x -= 0.4
	if dim >= 1.0:
		# reset and randomize a frame (a new one)
		$MovingBackground.frame = ($MovingBackground.frame + (randi() % ($MovingBackground.vframes - 1)) + 1) % $MovingBackground.vframes
		$MovingBackground.position.x = 0
		appearing = true
	if dim < -2.0:
		appearing = false
	
	if appearing: 
		dim -= 0.02
	else:
		dim += 0.02
	
	if dim > 0.0 and dim < 1.0:
		$Dim.color.a = dim

func _process(delta):
	handleBackground()
