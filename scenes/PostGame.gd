extends Node2D

@export var canProceed: bool = false

var _exitOverlay

func _ready():
	_exitOverlay = Res.ExitOverlayObject.instantiate()
	add_child(_exitOverlay)
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
	var exitPressed: bool = Global.isExitEvent(event)
	var usePressed: bool = (event.is_action_pressed('game_use') or event.is_action_pressed('kb_use')) and canProceed
	if Net.isOnline:
		# Only the host advances; everyone travels together via Net.to_lobby().
		if Net.isHost:
			if exitPressed:
				if _exitOverlay.request("press [exit] again to leave game"):
					Net.to_lobby()
			elif usePressed:
				Net.to_lobby()
		elif exitPressed:
			if _exitOverlay.request("press [exit] again to leave game"):
				Net.leave_to_menu()
		return
	if exitPressed:
		if _exitOverlay.request("press [exit] again to leave game"):
			Global.goToLobby()
	elif usePressed:
		Global.goToLobby()

func allowProceed():
	canProceed = true
	if Net.isOnline and not Net.isHost:
		# Guests can't advance the podium; say so instead of prompting.
		$HintHolder/LobbyHint.setText("waiting for host...")
	$HintHolder.show()
