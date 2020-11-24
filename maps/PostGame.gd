extends Node2D

func _ready():
	var winnerTeam = Global.getWinnerTeamByScore()
	for i in range(4):
		if Global.playersJoined[i]:
			if Global.playersTeam[i] == winnerTeam:
				Global.playersCrowned[i] = true
			else:
				Global.playersCrowned[i] = false
	get_tree().get_root().add_child(Global.Dim.instance())
