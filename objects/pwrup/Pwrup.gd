extends Area2D

export(String) var pwrupName = 'revolver'

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

func _on_Pwrup_body_entered(body):
	if body.is_in_group('players'):
		if body.alive:
			body.pickup(pwrupName)
			remove()
