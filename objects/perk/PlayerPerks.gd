extends Node2D

signal finished()

export(int) var playerId
var isFinished = false

func _ready():
	if !Global.playersJoined[playerId]:
		hide()
		isFinished = true
	$Team.color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Face.frame = Global.playersSkin[playerId]
	$PerkCard.hide()

func dealt():
	$PerkCard.show()

func _input(event):
	if event.device == playerId && $PerkCard.visible && Input.is_action_just_pressed("ui_accept"):
		if !$PerkCard.revealed:
			$PerkCard.reveal()
			Global.playersPerks[playerId].append($PerkCard.perkInt)
		else:
			isFinished = true
