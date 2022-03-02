extends Node2D

# menustate helper:
#  0 - local/multi
#  1 - local - lobby
#  2 - multi - host/join
#  3 - multi - lobby
var menuState = 0
var isLocal = true

# Called when the node enters the scene tree for the first time.
func _ready():
	get_node('/root/Music').play('menu')

func _input(event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	if (Input.is_action_just_pressed("pl_nav_down") ||
		Input.is_action_just_pressed("pl_nav_up")):
		isLocal = !isLocal
		if isLocal:
			$GameTypeHolder/Anim.play("wobble_local")
			$GameTypeHolder/OnlineHolder.scale = Vector2.ONE
			$GameTypeHolder/OnlineHolder.rotation_degrees = 0
		if !isLocal:
			$GameTypeHolder/Anim.play("wobble_online")
			$GameTypeHolder/LocalHolder.scale = Vector2.ONE
			$GameTypeHolder/LocalHolder.rotation_degrees = 0
	if Input.is_action_just_pressed("ui_accept"):
		if isLocal:
			get_tree().change_scene("res://Lobby.tscn")
		else:
			#coming soon
			#menuState = 2
			pass
