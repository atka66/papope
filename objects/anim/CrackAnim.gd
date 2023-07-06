extends Node2D

func _ready():
	$Crack.restart()
	$Audio.stream = Res.AudioWhipHuts.pick_random()
	$Audio.play()

func _process(delta):
	if !$Crack.emitting && !$Audio.playing:
		queue_free()
