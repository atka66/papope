extends TextureRect

func _ready():
	texture.current_frame = randi() % texture.frames
