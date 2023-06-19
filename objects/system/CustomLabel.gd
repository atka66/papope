@tool
extends Node2D

#@export var text: String = 'sample-text':
#	set(new_text):
#		text = new_text
#		setText(new_text)

@export var fontSize: int = 1:
	set(new_fontSize):
		fontSize = new_fontSize
		setFontSize(new_fontSize)

func _ready():
#	setText(text)
	setFontSize(fontSize)

func setText(new_text):
	pass
	
func setFontSize(new_fontSize):
	$PlaceholderSprite.scale = Vector2(new_fontSize, new_fontSize)
