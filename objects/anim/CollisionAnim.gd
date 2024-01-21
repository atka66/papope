extends Node2D

func _ready():
	$Audio.stream = Res.AudioContactPlayer.pick_random()
	$Audio.play()

