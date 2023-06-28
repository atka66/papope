extends Area2D

func _on_body_entered(body):
	if body.get_collision_layer_value(1): # might need to replace with group check
		body.inSpace = true
		print("enter")


func _on_body_exited(body):
	if body.get_collision_layer_value(1):
		body.inSpace = false
		print("exit")
