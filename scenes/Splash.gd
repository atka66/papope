extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	await get_tree().create_timer(1.0).timeout
	print(get_node("/root/Music"))
	get_node("/root/Music").play('splash')
	$Anim.play("splash")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func toLobby() -> void:
	print("todo go to lobby")
	pass
