extends StaticBody2D

export(String, 'revolver', 'dynamite') var pwrupName = 'revolver'

func _ready():
	$PwrupSprite.frames = Global.PwrupSprites[pwrupName]
	$SpawnAnim.play()

func _on_SpawnAnim_animation_finished():
	$SpawnAnim.hide()

func remove():
	var despawnAnim = Global.DespawnAnim.instance()
	despawnAnim.position = global_position - Vector2(0, 8)
	get_tree().get_root().add_child(despawnAnim)
	queue_free()
