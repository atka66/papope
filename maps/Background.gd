tool
extends ColorRect

func _ready():
	var noise = OpenSimplexNoise.new()
	noise.seed = randi()
	noise.period = 64.0
	noise.persistence = 0.6
	var noiseTexture = NoiseTexture.new()
	noiseTexture.noise = noise
	noiseTexture.seamless = true
	material.set_shader_param("noise", noiseTexture)
	
	var rvalue = randf()
	material.set_shader_param("r", rvalue)
	material.set_shader_param("b", 1.0 - rvalue)
