extends Node2D

func _ready():
	Global.MusicNode.play('splash')
	$Anim.play("splash")

func _input(event):
	if event.is_action_pressed("skip"):
		toLobby()

func toLobby() -> void:
	Global.goToLobby()
