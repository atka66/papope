extends StaticBody2D

func _ready():
	$SpawnAnim.play()

func _on_SpawnAnim_animation_finished():
	$SpawnAnim.hide()

func _on_remove():
	var despawnAnim = Global.DespawnAnim.instance()
	despawnAnim.position = global_position
	get_tree().get_root().add_child(despawnAnim)
	queue_free()
