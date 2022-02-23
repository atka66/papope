extends Node

func play(stage):
	var audioStream = null
	match stage:
		'lobby':
			audioStream = Res.AudioMusicLobby
		'postgame':
			audioStream = Res.AudioMusicPostGame
		'hell':
			audioStream = Res.AudioMusicHell
		'space':
			audioStream = Res.AudioMusicSpace
	$Audio.stream = audioStream
	$Audio.play()
