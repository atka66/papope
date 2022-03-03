extends Node

var muted = false

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
		'conveyor':
			audioStream = Res.AudioMusicConveyor
	if $Audio.stream != audioStream:
		$Audio.stream = audioStream
		if !muted:
			$Audio.play()

func mute():
	muted = !muted
	if muted:
		$Audio.stop()
	else:
		$Audio.play()
