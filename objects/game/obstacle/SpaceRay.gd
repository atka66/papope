extends Node2D

func _process(delta):
	if $Phase2.visible:
		Global.shakeScreen(3)
