extends Node

var isZeroPlaying = true

func play(stage):
	var audioFrom = $Audio0
	var audioTo = $Audio1
	if !isZeroPlaying:
		audioFrom = $Audio1
		audioTo = $Audio0
	match stage:
		'lobby':
			audioTo.stream = Res.AudioMusicLobby
		'postgame':
			audioTo.stream = Res.AudioMusicPostGame
		'hell':
			audioTo.stream = Res.AudioMusicHell
		_:
			audioTo.stream = null
	audioFrom.stop()
	audioTo.seek(0)
	audioTo.play()
