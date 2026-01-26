extends Node2D

@export var frame: int = 0
@export var slot: int = 0

var falling: bool = false
var rot = 0
var velocity: Vector2 = Vector2.ZERO

func _ready():
	$Sprite.hframes = len(Global.PerkEnum) + 1
	$Sprite.frame = frame

func bump() -> void:
	$Anim.play("bump")

func dispose() -> void:
	var fallTime : float = randf_range(0.5, 0.9)

	var height = randi_range(800, 1000)
	var ySubtween = create_tween()
	ySubtween.tween_property($Sprite, "position:y", -height * 0.1, fallTime * 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ySubtween.tween_property($Sprite, "position:y", height * 0.9, fallTime * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	var fallTween = create_tween().set_parallel(true)
	fallTween.tween_subtween(ySubtween)
	fallTween.tween_property($Sprite, "position:x", randi_range(-50, 50), fallTime)
	fallTween.tween_property($Sprite, "rotation_degrees", randi_range(-1000, 1000), fallTime)
	fallTween.chain().tween_callback(explode)

func explode() -> void:
	var explosionAnim = Res.ExplosionAnimObject.instantiate()
	explosionAnim.position = global_position + $Sprite.position
	explosionAnim.harmful = false
	explosionAnim.shakePwr = 20
	get_tree().get_current_scene().add_child(explosionAnim)
	queue_free()
