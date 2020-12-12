extends Node2D

signal finished()

export(int) var playerId
var isFinished = false

func _ready():
	if !Global.playersJoined[playerId]:
		hide()
		isFinished = true

func _input(event):
	if event.device == playerId && Input.is_action_just_pressed("ui_accept"):
		if !$PerkCard.revealed:
			$PerkCard.reveal()
		else:
			isFinished = true
