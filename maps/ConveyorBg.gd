extends ColorRect

var noise = OpenSimplexNoise.new()
var value = 0.0

func _ready():
	noise.seed = randi()

func _process(delta):
	var rgnoise = (noise.get_noise_1d(value) + 1) / 5
	var rnoise = (noise.get_noise_1d(value + 100) + 1) / 4
	color = Color(rnoise + rgnoise, rgnoise, 0.0, 1.0)
	value += 2.0
