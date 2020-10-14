extends Node2D

export var text = ''
export var fontSize = 1
export(Array, SpriteFrames) var frames

func set_text(_text):
	$Label.text = _text

func _ready():
	set_text(text)
	$Label.rect_scale = Vector2(fontSize, fontSize)
	if frames.size() > 0:
		$AnimatedSprite1.set_sprite_frames(frames[0])
		$AnimatedSprite1.play()
	if frames.size() > 1:
		$AnimatedSprite2.set_sprite_frames(frames[1])
		$AnimatedSprite2.play()
