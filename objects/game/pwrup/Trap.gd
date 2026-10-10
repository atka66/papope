extends Area2D

@export var originPlayerId: int = 0
@export var armed: bool = false
var conveyed: bool = false

func _ready():
	if Global.MapControllerNode.isNightclub:
		$Sprite.modulate = Color.BLACK

func _process(delta):
	if conveyed:
		position.x += Global.CONVEYOR_SPEED.x * delta

func spring(entity: Node2D) -> void:
	if armed:
		if Net.isOnline and not multiplayer.is_server():
			return # host authorizes springs; guests reveal via Net.trap_sprung
		if entity.is_in_group('trappables'):
			entity.getTrapped(originPlayerId)
			if Net.isOnline:
				Net.trap_sprung.rpc(global_position)
			showSprung()

func showSprung() -> void:
	# Visual reveal only (damage/flags arrive via host state sync).
	if not armed:
		return
	$Anim.play("spring")
	var crack = Res.CrackAnimObject.instantiate()
	crack.position = position
	Global.addToScene(crack)

func convey() -> void:
	conveyed = true

func fallDown() -> void:
	armed = false
	$Anim.play('fall')

func _on_body_entered(body):
	spring(body)

func _on_area_entered(area):
	spring(area)
