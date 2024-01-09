extends Node2D

@export var text: String = 'sample_text'
@export var size: int = 2
@export var color: Color = Color.WHITE

var velocity = Vector2.ZERO
var gravity = 0.2

func _ready():
	position = Vector2(
		max(min(position.x, 648), 32),
		max(min(position.y, 349), 29)
	)
	velocity = Vector2(randf_range(0.3, 1.5) * [-1, 1].pick_random(), randi_range(-4, -3))
	
	rotation = velocity.x / 5
	
	$CustomLabel.setFontSize(size)
	$CustomLabel.setText(text)
	$CustomLabel.setFontColor(color)

func _process(delta):
	position += velocity
	velocity.y += gravity
	if velocity.y > 0:
		rotation *= 1.1
