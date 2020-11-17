extends Node2D

func showCount(cnt):
	var label = Global.CustomLabel.instance()
	label.text = cnt
	label.fontSize = 2
	label.outline = true
	label.aliveTime = 1
	label.alignment = Label.ALIGN_CENTER
	add_child(label)

func _ready():
	for i in range(3):
		showCount(str(3 - i))
		yield(get_tree().create_timer(1), "timeout")
	if (get_tree().get_current_scene().get_name() == 'Lobby'):
		Global.goToMap()
	else:
		showCount("go!")
		Global.playersFrozen = false
