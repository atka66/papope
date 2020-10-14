extends Label

export var fontSize = 1

func _ready():
	rect_position.x = -500
	rect_size.x = 500
	rect_scale = Vector2(fontSize, fontSize)
