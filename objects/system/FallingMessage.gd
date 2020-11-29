extends KinematicBody2D

export(String) var text = ''
export(Color) var color = Color.white
export(int) var size = 2
export(AudioStreamOGGVorbis) var audio = null

var velocity = Vector2.ZERO
var gravity = 15

func _ready():
	position = Vector2(
		max(min(position.x, 648), 32),
		max(min(position.y, 349), 29)
	)
	
	velocity = Vector2(((randi() % 4) + 1) * (((randi() % 2) * 2) - 1), -((randi() % 3) + 10)) * 20
	rotation = velocity.x / 200
	var label = Res.CustomLabel.instance()
	label.position.y = 16
	label.color = color
	label.text = text
	label.fontSize = size
	label.outline = true
	label.aliveTime = 0
	label.alignment = Label.ALIGN_CENTER
	label.animate = false
	label.audio = audio
	add_child(label)

func _physics_process(delta):
	velocity = move_and_slide(velocity)
	velocity.y += gravity

func _process(delta):
	if velocity.y > 0:
		rotation *= 1.1


func _on_AnimationPlayer_animation_finished(anim_name):
	yield(get_node('CustomLabel/Audio'), "finished")
	queue_free()
