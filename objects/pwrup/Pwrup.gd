extends Area2D

export(String) var pwrupName = 'revolver'

var conveyed = false

func _ready():
	$Container/PwrupSprite.frames = Res.PwrupSprites[pwrupName]
	$Container/SpawnAnim.play()

func _process(delta):
	if conveyed:
		position.x -= Global.CONVEYOR_VEL_AREA

func _on_SpawnAnim_animation_finished():
	$Container/SpawnAnim.hide()

func remove():
	var despawnAnim = Res.DespawnAnim.instance()
	despawnAnim.position = global_position - Vector2(0, 8)
	get_tree().get_current_scene().add_child(despawnAnim)
	queue_free()

func _on_Pwrup_body_entered(body):
	if body.is_in_group('players'):
		if body.alive && !Global.playersFrozen:
			body.pickup(pwrupName)
			remove()

func fell():
	get_tree().get_nodes_in_group('controllers')[0].playFallenPwrups()
	queue_free()
