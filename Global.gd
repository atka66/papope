extends Node2D

const playerColors = {
	0: Color(0.9, 0.2, 0.2),
	1: Color(0, 0.3, 0.7),
	2: Color(0.5, 0.9, 0.0),
	3: Color(1.0, 0.7, 0)
}

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
