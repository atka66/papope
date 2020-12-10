extends KinematicBody2D

var velocity = Vector2.ZERO
var gravity = 25

func _ready():
	$Audio.play()
	position = Vector2(
		max(min(position.x, 648), 32),
		max(min(position.y, 349), 29)
	)
	velocity = Vector2(((randi() % 4) + 1) * (((randi() % 2) * 2) - 1), -((randi() % 3) + 10)) * 20
	rotation = velocity.x / 200

func _physics_process(delta):
	velocity = move_and_slide(velocity)
	velocity.y += gravity

func _process(delta):
	if velocity.y > 0:
		rotation *= 1.1


func _on_AnimationPlayer_animation_finished(anim_name):
	yield($Audio, "finished")
	queue_free()
