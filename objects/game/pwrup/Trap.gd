extends Area2D

@export var originPlayerId: int = 0
@export var armed: bool = false
var conveyed: bool = false

func _ready():
	if Global.MapControllerNode.isNightclub:
		$Sprite.modulate = Color.BLACK

# TODO account delta
func _process(delta):
	if conveyed:
		position.x -= Global.CONVEYOR_VEL_AREA

func spring(entity: Node2D) -> void:
	if armed:
		if entity.is_in_group('trappables'):
			entity.getTrapped(originPlayerId)
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
