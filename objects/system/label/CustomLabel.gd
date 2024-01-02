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

@export var alignment: Control.LayoutPreset = Control.LayoutPreset.PRESET_TOP_LEFT:
	set(new_alignment):
		alignment = new_alignment
		setAlignment(new_alignment)

@export var aliveTime: int = 0

func _ready():
	$Label.label_settings = $Label.label_settings.duplicate()
	setText(text)
	setFontSize(fontSize)
	setAlignment(alignment)
	setAliveTime(aliveTime)

func setText(new_text):
	$Label.text = new_text
	
func setFontSize(new_fontSize):
	$Label.label_settings.font_size = new_fontSize * 10

func setAlignment(new_alignment):
	$Label.set_anchors_and_offsets_preset(new_alignment)

func setAliveTime(new_aliveTime):
	if !Engine.is_editor_hint() && new_aliveTime > 0:
		timeDisappear(new_aliveTime)

func timeDisappear(time) -> void:
	await get_tree().create_timer(time).timeout
	queue_free()
