extends Node2D

func _ready():
	#await get_tree().create_timer(1.0).timeout #TODO check if needed
	Global.MusicNode.play('splash')
	$Anim.play("splash")

func _input(event):
	if event.is_action_pressed("skip"):
		toLobby()

func toLobby() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
