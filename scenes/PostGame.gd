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
			Net.leave_to_menu()
		return
	if event.is_action_pressed('quit') or ((event.is_action_pressed('accept') or event.is_action_pressed('kb_accept')) and canProceed):
		Global.goToLobby()

func allowProceed():
	canProceed = true
	if Net.isOnline and not Net.isHost:
		# Guests can't advance the podium; say so instead of prompting.
		$HintHolder/OSprite.hide()
		$HintHolder/LobbyHint.setText("waiting for host...")
	$HintHolder.show()
