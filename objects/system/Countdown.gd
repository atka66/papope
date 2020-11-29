extends Node2D

func showCount(cnt, audio):
	var label = Res.CustomLabel.instance()
	label.text = cnt
	label.fontSize = 2
	label.outline = true
	label.aliveTime = 1
	label.alignment = Label.ALIGN_CENTER
	label.audio = audio
	add_child(label)

func _ready():
	for i in range(3):
		showCount(str(3 - i), Res.AudioMsg)
		yield(get_tree().create_timer(1, false), "timeout")
	if (get_tree().get_current_scene().get_name() == 'Lobby'):
		Global.goToMap()
	else:
		showCount("go!", Res.AudioRoundGo)
		Global.playersFrozen = false
