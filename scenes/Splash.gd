extends Node2D

func _ready():
	Global.MusicNode.play('splash')
	$Anim.play("splash")

func _input(event):
	if event.is_action_pressed("skip") or event.is_action_pressed("kb_use"):
		toLobby()

func toLobby() -> void:
	Global.goToMainMenu()
