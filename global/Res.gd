extends Node

@onready var CustomLabelObject = preload("res://objects/system/label/CustomLabel.tscn")
@onready var PlayerObject = preload("res://objects/game/Player.tscn")
@onready var HudObject = preload("res://objects/game/hud/Hud.tscn")
@onready var SpawnAnimObject = preload("res://objects/anim/SpawnAnim.tscn")
@onready var CountdownObject = preload("res://objects/system/label/Countdown.tscn")

@onready var AudioRoundGo = preload("res://audio/sfx/system/round_go.ogg")

@onready var AudioPlayerDash = [
	preload("res://audio/sfx/player/dash_1.ogg"),
	preload("res://audio/sfx/player/dash_2.ogg"),
	preload("res://audio/sfx/player/dash_3.ogg")
]

@onready var AudioMusicDefault = preload("res://audio/music/default.ogg")
@onready var AudioMusicSplash = preload("res://audio/music/splash.ogg")
@onready var AudioMusicLobby = preload("res://audio/music/lobby.ogg")
@onready var AudioMusicPostGame = preload("res://audio/music/postgame.ogg")
@onready var AudioMusicHell = preload("res://audio/music/hell.ogg")
@onready var AudioMusicWestern = preload("res://audio/music/western.ogg")
@onready var AudioMusicSpace = preload("res://audio/music/space.ogg")
@onready var AudioMusicConveyor = preload("res://audio/music/conveyor.ogg")
