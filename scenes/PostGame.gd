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
	if Net.isOnline:
		# Only the host advances; everyone travels together via Net.to_lobby().
		if Net.isHost and (event.is_action_pressed('quit') or ((event.is_action_pressed('accept') or event.is_action_pressed('kb_accept')) and canProceed)):
			Net.to_lobby()
		elif not Net.isHost and event.is_action_pressed('quit'):
			Net.leave()
			get_tree().change_scene_to_file("res://scenes/OnlineMenu.tscn")
		return
	if event.is_action_pressed('quit') or ((event.is_action_pressed('accept') or event.is_action_pressed('kb_accept')) and canProceed):
		Global.goToLobby()

func allowProceed():
	canProceed = true
	$HintHolder.show()
