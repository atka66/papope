extends Node2D

export var text = ''
export var fontSize = 1
export var frames = ''

func _ready():
	$Label.rect_scale = Vector2(fontSize, fontSize)
	$Label.text = text
	$AnimatedSprite.set_sprite_frames(Global.labelAnimations[frames])
	$AnimatedSprite.play()
