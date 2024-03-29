extends Node

func _ready():
	Global.MusicNode = self

func play(stage: String) -> void:
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
		'industrial':
			audioStream = Res.AudioMusicIndustrial
	if $Audio.stream != audioStream:
		$Audio.stream = audioStream
		$Audio.play()
