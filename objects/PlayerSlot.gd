extends Node2D

export var playerId = 0

#TODO remove
var pc = false
var pj = false
var cd = false

func _ready():
	pass # Replace with function body.

func isPlayerConnected():
	return pc

func isPlayerJoined():
	return pj

func isCountingDown():
	return cd
	
#TODO remove
func _input(event):
	if Input.is_key_pressed(KEY_0): pc = !pc
	if Input.is_key_pressed(KEY_1): pj = !pj
	if Input.is_key_pressed(KEY_2): cd = !cd

func handleSpawnSprite():
	if isPlayerConnected() and !isPlayerJoined() and !isCountingDown():
		$SpawnSprite.show()
	else:
		$SpawnSprite.hide()

func handleControllerSprite():
	var color = Color.white
	if isPlayerConnected():
		if isPlayerJoined():
			color = Global.playerColors[playerId]
	else:
		color.a = 0.5
	$ControllerSprite.modulate = color

func handleHints():
	$JoinLabel.hide()
	$CancelLabel.hide()
	$LeaveLabel.hide()
	$OfflineLabel.hide()
	
	if isPlayerConnected():
		if isPlayerJoined():
			if isCountingDown():
				$CancelLabel.show()
			else:
				$LeaveLabel.show()
		else:
			if !isCountingDown():
				$JoinLabel.show()
	else:
		$OfflineLabel.show()

func _process(delta):
	handleSpawnSprite()
	handleControllerSprite()
	handleHints()
