extends ColorRect

func _ready():
	var noise = material.get_shader_parameter("noise").noise
	noise.seed = randi()
