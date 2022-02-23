extends Node2D

var canProceed = false

func _ready():
	get_node('/root/Music').play('postgame')
	$LobbyHint.hide()
	var winnerTeam = Global.getWinnerTeamByScore()
	for i in range(4):
		if Global.playersJoined[i]:
			if Global.playersTeam[i] == winnerTeam:
				Global.playersCrowned[i] = true
			else:
				Global.playersCrowned[i] = false
	get_tree().get_root().add_child(Res.Dim.instance())
	
	yield(get_tree().create_timer(2.0), "timeout")
	$AudioCash.play()
	yield(get_tree().create_timer(6.0), "timeout")
	canProceed = true
	$LobbyHint.show()

func _input(event):
	if Input.is_action_just_pressed("ui_accept") && canProceed:
		get_tree().change_scene("res://Lobby.tscn")
