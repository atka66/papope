extends Node2D

func _ready():
	$MapName.set_text(Global.selectedMap)


func _on_Anim_animation_finished(anim_name):
	hide()
	yield($MapName/Audio, "finished")
	queue_free()
