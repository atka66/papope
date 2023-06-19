@tool
extends Node2D

@export var text: String = 'sample-text':
	set(new_text):
		text = new_text
		setText(new_text)

@export var fontSize: int = 1:
	set(new_fontSize):
		fontSize = new_fontSize
		setFontSize(new_fontSize)
		
@export var alignment = HORIZONTAL_ALIGNMENT_CENTER:
	set(new_alignment):
		alignment = new_alignment
		setAlignment(new_alignment)

func _ready():
	setText(text)
	setFontSize(fontSize)
	setAlignment(alignment)

func setText(new_text):
	$Label.text = new_text
	
func setFontSize(new_fontSize):
	#$Label.set_size(Vector2(new_fontSize, new_fontSize))
	$Label.add_theme_font_size_override("theme_override_font_sizes/font_size", new_fontSize)
	pass

func setAlignment(new_alignment):
	$Label.horizontal_alignment = new_alignment
	match new_alignment:
		HORIZONTAL_ALIGNMENT_LEFT:
			$Label.anchors_preset = Control.PRESET_TOP_LEFT
		HORIZONTAL_ALIGNMENT_CENTER:
			$Label.anchors_preset = Control.PRESET_CENTER_TOP
		HORIZONTAL_ALIGNMENT_RIGHT:
			$Label.anchors_preset = Control.PRESET_TOP_RIGHT
