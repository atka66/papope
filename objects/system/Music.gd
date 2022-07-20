extends Node

var muted = false

func play(stage):
	var audioStream = Res.AudioMusicDefault
	match stage:
		'splash':
			audioStream = Res.AudioMusicSplash
		'menu':
			audioStream = Res.AudioMusicLobby
		'postgame':
			audioStream = Res.AudioMusicPostGame
		'hell':
			audioStream = Res.AudioMusicHell
		'western':
			audioStream = Res.AudioMusicWestern
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
