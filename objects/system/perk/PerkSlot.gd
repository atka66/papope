extends Node2D

@export var frame: int = 0
@export var slot: int = 0

var falling: bool = false
var rot = 0
var velocity: Vector2 = Vector2.ZERO

func _ready():
	$Sprite.hframes = len(Global.PerkEnum) + 1
	$Sprite.frame = frame

func _process(delta):
	if falling:
		velocity.y += 1
		$Sprite.rotation_degrees += rot
		$Sprite.position += velocity

func bump() -> void:
	$Anim.play("bump")

func dispose():
	velocity = Vector2(2.0 - (randf() * 4.0), -2.0 - (randf() * 2.0))
	rot = 30 - (randi() % 30)
	falling = true
	await get_tree().create_timer(1.0).timeout
	var explosionAnim = Res.ExplosionAnimObject.instantiate()
	explosionAnim.position = global_position + $Sprite.position
	explosionAnim.harmful = false
	explosionAnim.shakePwr = 20
	get_tree().get_current_scene().add_child(explosionAnim)
	queue_free()
