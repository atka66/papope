extends Node2D

export var playerId = 0

#TODO remove
var cd = false

func _ready():
	pass # Replace with function body.

func isPlayerConnected():
	return Global.playersConnected[playerId]

func isPlayerJoined():
	return Global.playersJoined[playerId]

func isCountingDown():
	return cd
	
#TODO remove
func _input(event):
	if Input.is_key_pressed(KEY_W):
		Global.playersJoined[playerId] = !Global.playersJoined[playerId]
	if Input.is_key_pressed(KEY_E): cd = !cd

func handleSpawnSprite():
	if isPlayerConnected() and !isPlayerJoined() and !isCountingDown():
		$SpawnSprite.show()
	else:
		$SpawnSprite.hide()

func handleControllerSprite():
	var color = Color.white
	if isPlayerConnected():
		if isPlayerJoined():
			color = Global.PLAYER_COLORS[playerId]
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
