extends Node2D

signal finished()

func _ready():
	modulate.a = 0
	for i in range(4):
		if !Global.playersJoined[i]:
			#get_node('Card' + str(i)).hide() TODO
			pass
	
	await get_tree().create_timer(1.5).timeout
	$Anim.play("appear")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
