extends Node2D

export(bool) var silent = false
export(int) var frame = 0
export(int) var slot = 0

var falling = false
var rot = 0
var currVel = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite.hframes = len(Global.PerkEnum) + 1
	$Sprite.frame = frame
	if !silent:
		$Anim.play("appear")

func _process(delta):
	if falling:
		currVel.y += 0.5
		$Sprite.rotation_degrees += rot
		$Sprite.position += currVel
	

func dispose():
	if true:
		currVel = Vector2(2.0 - (randf() * 4.0), -2.0 - (randf() * 2.0))
		rot = 30 - (randi() % 30)
		falling = true
		yield(get_tree().create_timer(1.0), "timeout")
		var explosionAnim = Res.ExplosionAnim.instance()
		explosionAnim.position = global_position + $Sprite.position
		explosionAnim.harmful = false
		explosionAnim.shakePwr = 10
		get_tree().get_current_scene().add_child(explosionAnim)
	queue_free()
