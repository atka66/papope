extends Area2D

@export var type: Global.PwrupEnum = Global.PwrupEnum.DYNAMITE
var conveyed: bool = false
var netSpawner: int = -1 # online: spawner index for host-driven despawn sync

# Called when the node enters the scene tree for the first time.
func _ready():
	if Global.MapControllerNode.isNightclub:
		$Container/Sprite.modulate = Color.BLACK
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
		position.x += Global.CONVEYOR_SPEED.x * delta

func spawnAnimation():
	var anim = Res.SpawnPwrupAnimObject.instantiate()
	anim.position = global_position
	Global.addToScene(anim)

func despawn():
	spawnAnimation()
	queue_free()

func _on_body_entered(body):
	if body.is_in_group('players'):
		# Online pickups are host-authoritative; guests apply via state sync.
		if Net.isOnline and not multiplayer.is_server():
			return
		if body.alive && !Global.playersFrozen:
			body.pickup(type)
			if Net.isOnline:
				Net.despawn_pwrup.rpc(netSpawner)
			despawn()

func convey() -> void:
	conveyed = true

func fallDown() -> void:
	conveyed = false
	$Anim.play('fall')
