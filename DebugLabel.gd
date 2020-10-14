extends Label

func _process(delta):
	text = 'Player connected: ' + String(get_node('/root/Lobby/PlayerSlot1').pc) + '\n\n'\
		+ 'Player joined: ' + String(get_node('/root/Lobby/PlayerSlot1').pj) + '\n\n'\
		+ 'Counting down: ' + String(get_node('/root/Lobby/PlayerSlot1').cd)
