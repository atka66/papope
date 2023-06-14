extends Node2D

func _ready():
	# delayed start for browser
	yield(get_tree().create_timer(1.0), "timeout")
	get_node('/root/Music').play('splash')
	$Anim.play("splash")

func _input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()

func toLobby():
	get_tree().change_scene("res://Lobby.tscn")
