extends Node2D

func _ready():
	get_node('/root/Music').play('splash')
	$MenuTimer.start(2.2)

func _on_MenuTimer_timeout():
	get_tree().change_scene("res://Lobby.tscn")
