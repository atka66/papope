extends Node2D

@export var text: String = 'sample_text'
@export var size: int = 2
@export var color: Color = Color.WHITE

var velocity = Vector2.ZERO
var gravity = 0.4

func _ready():
	position = Vector2(
		max(min(position.x, 1296), 64),
		max(min(position.y, 736), 32)
	)
	velocity = Vector2(randf_range(0.6, 2.5) * [-1, 1].pick_random(), randi_range(-7, -5))
	
	rotation = velocity.x / 7
	
	$CustomLabel.setFontSize(size)
	$CustomLabel.setText(text)
	$CustomLabel.setFontColor(color)

func _process(delta):
	position += velocity
	velocity.y += gravity
	if velocity.y > 0:
		rotation *= 1.1
