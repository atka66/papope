extends Node

func play(stage):
	var audioStream = Res.AudioMusicDefault
	match stage:
		'menu':
			audioStream = Res.AudioMusicLobby
		'postgame':
			audioStream = Res.AudioMusicPostGame
		'hell':
			audioStream = Res.AudioMusicHell
		'space':
			audioStream = Res.AudioMusicSpace
	if $Audio.stream != audioStream:
		$Audio.stream = audioStream
		$Audio.play()
