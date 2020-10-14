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

func _process(delta):
	var controllerColor = Color.white
	if isPlayerConnected():
		if isPlayerJoined():
			controllerColor = Global.playerColors[playerId]
			if isCountingDown():
				$JoinHint.text = 'cancel'
				pass
			else:
				$JoinHint.text = 'leave'
				pass
		else:
			if isCountingDown():
				$SpawnSprite.visible = false
				$JoinHint.text = ''
			else:
				$SpawnSprite.visible = true
				$JoinHint.text = 'join'
		controllerColor.a = 1.0
	else:
		controllerColor.a = 0.5
		$JoinHint.text = ''
	$ControllerSprite.modulate = controllerColor
