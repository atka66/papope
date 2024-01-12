extends Node2D

func _ready():
	$Audio.stream = Res.AudioPlayerCollide.pick_random()
	$Audio.play()

