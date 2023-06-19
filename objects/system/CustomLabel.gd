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

enum ALIGNMENTS {LEFT, CENTER, RIGHT}
@export var alignment: ALIGNMENTS = ALIGNMENTS.LEFT:
	set(new_alignment):
		alignment = new_alignment
		setAlignment(new_alignment)

@export var aliveTime: int = 0

func _ready():
#	setText(text)
	setFontSize(fontSize)
	setAlignment(alignment)
	setAliveTime(aliveTime)

func setText(new_text):
	pass
	
func setFontSize(new_fontSize):
	$PlaceholderSprite.scale = Vector2(new_fontSize, new_fontSize)

func setAlignment(new_alignment):
	match new_alignment:
		ALIGNMENTS.LEFT:
			$PlaceholderSprite.offset.x = 0
		ALIGNMENTS.CENTER:
			$PlaceholderSprite.offset.x = -18
		ALIGNMENTS.RIGHT:
			$PlaceholderSprite.offset.x = -36

func setAliveTime(new_aliveTime):
	if !Engine.is_editor_hint() && new_aliveTime > 0:
		timeDisappear(new_aliveTime)

func timeDisappear(time) -> void:
	await get_tree().create_timer(time).timeout
	queue_free()
