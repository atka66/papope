extends Node2D

func showCount(cnt, size, audio):
	var label = Res.CustomLabel.instance()
	label.text = cnt
	label.fontSize = size
	label.outline = true
	label.aliveTime = 1
	label.alignment = Label.ALIGN_CENTER
	label.audio = audio
	add_child(label)

func _ready():
	for i in range(3):
		showCount(str(3 - i), 2, Res.AudioMsg)
		yield(get_tree().create_timer(1), "timeout")
	if (get_tree().get_current_scene().get_name() == 'Lobby'):
		# assign max HPs and go to map
		for i in range(4):
			match Global.options['mode'][Global.optionsSelected['mode']]:
				'normal':
					Global.playersMaxHp[i] = 100
				'one-hit':
					Global.playersMaxHp[i] = 1
				'cards':
					Global.playersMaxHp[i] = 100
		Global.goToMap()
	else:
		showCount("go!", 3, Res.AudioRoundGo)
		Global.playersFrozen = false
		if Global.selectedMap == 'pacman':
			var spawn = get_parent().get_node('MapController').initGhostSpawn()
