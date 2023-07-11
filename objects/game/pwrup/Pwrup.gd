extends Area2D

@export var type: Global.PwrupEnum = Global.PwrupEnum.DYNAMITE

# Called when the node enters the scene tree for the first time.
func _ready():
	match type:
		Global.PwrupEnum.DYNAMITE:
			$Sprite.animation = 'dynamite'
		Global.PwrupEnum.REVOLVER:
			$Sprite.animation = 'revolver'
		Global.PwrupEnum.SHIELD:
			$Sprite.animation = 'shield'
		Global.PwrupEnum.TRAP:
			$Sprite.animation = 'trap'
		Global.PwrupEnum.WHIP:
			$Sprite.animation = 'whip'
	spawnAnimation()

func spawnAnimation():
	var anim = Res.SpawnPwrupAnimObject.instantiate()
	anim.position = global_position
	Global.addToScene(anim)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func despawn():
	spawnAnimation()
	queue_free()

func _on_body_entered(body):
	if body.is_in_group('players'):
		if body.alive && !Global.playersFrozen:
			body.pickup(type)
			despawn()
