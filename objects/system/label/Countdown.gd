extends Node2D

func showCount(cnt: String, size: int, audio: Resource) -> void:
	var label = Res.CustomLabelObject.instantiate()
	label.text = cnt
	label.fontSize = size
	label.alignment = Control.LayoutPreset.PRESET_CENTER
	label.aliveTime = 1
	label.animation = 'boom_in'
	label.animation_out = 'float_out'
	label.audio = audio
	add_child(label)

func _ready():
	for i in range(3):
		showCount(str(3 - i), 8, Res.AudioPlayerDash.pick_random())
		await get_tree().create_timer(1.0).timeout
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
		showCount("go!", 12, null)
		Global.startRound()
