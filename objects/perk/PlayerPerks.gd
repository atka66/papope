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
	$RevealLabel.hide()

func dealt():
	$PerkCard.show()
	$RevealLabel.show()

func _input(event):
	if event.device == playerId && $PerkCard.visible && Input.is_action_just_pressed("ui_accept"):
		if !$PerkCard.revealed:
			$RevealLabel.hide()
			$PerkCard.reveal()
			Global.playersPerks[playerId].append($PerkCard.perkInt)
			yield(get_tree().create_timer(3), "timeout")
			isFinished = true
