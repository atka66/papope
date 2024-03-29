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

@export var fontColor: Color = Color.WHITE:
	set(new_fontColor):
		fontColor = new_fontColor
		setFontColor(new_fontColor)

@export var alignment: Control.LayoutPreset = Control.LayoutPreset.PRESET_TOP_LEFT:
	set(new_alignment):
		alignment = new_alignment
		setAlignment(new_alignment)

@export var aliveTime: int = 0

@export var animation: String = 'none':
	set(new_animation):
		animation = new_animation
		setAnimation(new_animation)

@export var animation_out: String = 'none'

@export var audio: AudioStream:
	set(new_audio):
		audio = new_audio
		setAudio(new_audio)

func _ready():
	$Container.hide()
	$Container/Label.label_settings = $Container/Label.label_settings.duplicate()
	setText(text)
	setFontSize(fontSize)
	setFontColor(fontColor)
	setAlignment(alignment)
	setAliveTime(aliveTime)
	setAnimation(animation)
	setAudio(audio)
	$Audio.play()

func setText(new_text):
	$Container/Label.text = new_text
	setAlignment(alignment)
	
func setFontSize(new_fontSize):
	$Container/Label.label_settings.font_size = new_fontSize * 10
	setAlignment(alignment)

func setFontColor(new_fontColor):
	$Container/Label.label_settings.font_color = new_fontColor

func setAlignment(new_alignment):
	$Container/Label.set_anchors_and_offsets_preset(new_alignment)

func setAliveTime(new_aliveTime):
	if !Engine.is_editor_hint() && new_aliveTime > 0:
		timeDisappear(new_aliveTime)

func setAnimation(new_animation):
	$Anim.play(new_animation)

func setAudio(new_audio):
	if new_audio != null:
		$Audio.stream = new_audio

func timeDisappear(time) -> void:
	await get_tree().create_timer(time).timeout
	$Anim.play(animation_out)
	await $Anim.animation_finished
	queue_free()
