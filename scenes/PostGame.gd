extends Node2D

@export var canProceed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.MusicNode.play('postgame')
	$LobbyHint.hide()
	var winnerTeam: int = Global.getWinnerTeamByScore()
	for i in range(4):
		if Global.playersJoined[i]:
			if Global.playersTeam[i] == winnerTeam:
				Global.playersCrowned[i] = true
			else:
				Global.playersCrowned[i] = false

func animationFinished() -> void:
	canProceed = true
	$LobbyHint.show()

func _input(event):
	if event.is_action_pressed('quit') or (event.is_action_pressed('accept') and canProceed):
		get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
