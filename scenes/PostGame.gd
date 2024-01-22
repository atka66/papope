extends Node2D

@export var canProceed: bool = false

func _ready():
	Global.MusicNode.play('postgame')
	$HintHolder.hide()
	var winnerTeam: int = Global.getWinnerTeamByScore()
	for i in range(4):
		if Global.playersJoined[i]:
			if Global.playersTeam[i] == winnerTeam:
				Global.playersCrowned[i] = true
			else:
				Global.playersCrowned[i] = false

func _input(event):
	if event.is_action_pressed('quit') or (event.is_action_pressed('accept') and canProceed):
		toLobby()

func toLobby():
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func allowProceed():
	canProceed = true
	$HintHolder.show()
