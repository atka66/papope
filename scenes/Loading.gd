extends Node2D

var shaderCache

func loadCache():
	shaderCache = Res.ShaderCacheObject.instantiate()
	get_tree().root.add_child(shaderCache)

func deleteCache():
	shaderCache.queue_free()

func _on_anim_animation_finished(anim_name):
	get_tree().change_scene_to_file("res://scenes/Splash.tscn")
