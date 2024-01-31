extends Node2D

func loadShaders():
	var shaderLoader = Res.ShaderLoaderObject.instantiate()
	shaderLoader.position = Vector2(5000, 5000)
	add_child(shaderLoader)

func _on_anim_animation_finished(anim_name):
	get_tree().change_scene_to_file("res://scenes/Splash.tscn")
