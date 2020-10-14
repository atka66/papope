extends Node2D

var dim = 1.0
var appearing = true

func handleLabels(connected):
	$PapopeLabel.visible = !connected
	$SubtitleLabel.visible = !connected

	$MenuHintLabel.visible = connected
	$MenuMovementHintLabel.visible = connected
	$MenuChangeSkinHintLabel.visible = connected
	$MenuChangeTeamHintLabel.visible = connected
	##TODO depend on setting
	$MenuNagivationHintLabel.visible = connected
	$IngameHintLabel.visible = connected
	$IngameMovementHintLabel.visible = connected
	$IngameAimHintLabel.visible = connected
	$IngameDashHintLabel.visible = connected
	$IngameUseHintLabel.visible = connected

func connectPlayer(playerId):
	Global.playersConnected[playerId] = true
	handleLabels(true)

func disconnectPlayer(playerId):
	Global.playersConnected[playerId] = false
	if !Global.isAnyPlayerConnected():
		handleLabels(false)

func _ready():
	handleLabels(false)
	$VersionLabel.set_text('V' + Global.VERSION)

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
