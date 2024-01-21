extends Node2D

@export var playerHit: bool = false

func _ready():
	$Crack.restart()
	$Audio.stream = Res.AudioWhipHuts.pick_random()
	$Audio.play()
	if playerHit:
		$AudioPlayerHit.play()

func _process(delta):
	if !$Crack.emitting && !$Audio.playing && !$AudioPlayerHit.playing:
		queue_free()
