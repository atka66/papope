extends Area2D

@export var type: Global.PwrupEnum = Global.PwrupEnum.DYNAMITE
var conveyed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	match type:
		Global.PwrupEnum.DYNAMITE:
			$Container/Sprite.animation = 'dynamite'
		Global.PwrupEnum.REVOLVER:
			$Container/Sprite.animation = 'revolver'
		Global.PwrupEnum.SHIELD:
			$Container/Sprite.animation = 'shield'
		Global.PwrupEnum.TRAP:
			$Container/Sprite.animation = 'trap'
		Global.PwrupEnum.WHIP:
			$Container/Sprite.animation = 'whip'
	$Container/Sprite.play()
	spawnAnimation()

func _process(delta):
	if conveyed:
		position.x -= Global.CONVEYOR_VEL_AREA

func spawnAnimation():
	var anim = Res.SpawnPwrupAnimObject.instantiate()
	anim.position = global_position
	Global.addToScene(anim)

func despawn():
	spawnAnimation()
	queue_free()

func _on_body_entered(body):
	if body.is_in_group('players'):
		if body.alive && !Global.playersFrozen:
			body.pickup(type)
			despawn()

func convey() -> void:
	conveyed = true

func fallDown() -> void:
	conveyed = false
	$Anim.play('fall')
