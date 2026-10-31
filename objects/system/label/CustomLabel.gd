@tool
extends Node2D

const CONTROL_COLOR := Color("8fd3ff")
const CONTROL_TOKEN_PATTERN := "\\[[A-Za-z0-9_]+\\]"

@export var text: String = 'sample-text':
	set(new_text):
		text = new_text
		_useSegments = false
		_render()

@export var controlColor: Color = CONTROL_COLOR:
	set(new_controlColor):
		controlColor = new_controlColor
		_render()

@export var fontSize: int = 1:
	set(new_fontSize):
		fontSize = new_fontSize
		_applyFontSize(new_fontSize)

@export var fontColor: Color = Color.WHITE:
	set(new_fontColor):
		fontColor = new_fontColor
		_applyFontColor(new_fontColor)

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

var _segments: Array = []
var _useSegments := false
var _tokenRegex: RegEx

func _init():
	_tokenRegex = RegEx.create_from_string(CONTROL_TOKEN_PATTERN)

func _ready():
	$Container.hide()
	_applyFontSize(fontSize)
	_applyFontColor(fontColor)
	setAlignment(alignment)
	setAliveTime(aliveTime)
	setAnimation(animation)
	setAudio(audio)
	$Audio.play()

## Plain text. `[action]` tokens are rendered in `controlColor`, brackets included.
func setText(new_text):
	text = new_text

## Explicit colored spans: [{ "text": String, "color": Color (optional) }, ...].
func setSegments(new_segments: Array):
	_segments = new_segments.duplicate(true)
	_useSegments = true
	_render()

func setFontSize(new_fontSize):
	fontSize = new_fontSize

func _applyFontSize(new_fontSize):
	var label := get_node_or_null("Container/Label") as RichTextLabel
	if label == null:
		return
	label.add_theme_font_size_override("normal_font_size", new_fontSize * 10)
	setAlignment(alignment)

func setFontColor(new_fontColor):
	fontColor = new_fontColor

func _applyFontColor(new_fontColor):
	var label := get_node_or_null("Container/Label") as RichTextLabel
	if label == null:
		return
	label.add_theme_color_override("default_color", new_fontColor)
	_render()

func setAlignment(new_alignment):
	var label := get_node_or_null("Container/Label") as RichTextLabel
	# Theme items are only resolved once the label enters the tree; shaping
	# before that would run with a null font.
	if label == null or !label.is_inside_tree():
		return
	label.set_anchors_and_offsets_preset(new_alignment)

func _render():
	var label := get_node_or_null("Container/Label") as RichTextLabel
	if label == null or !label.is_inside_tree():
		return
	var segments := _segments if _useSegments else _textToSegments(text)
	label.clear()
	for segment in segments:
		var segmentText: String = str(segment.get("text", ""))
		if segmentText.is_empty():
			continue
		var segmentColor: Color = segment.get("color", fontColor)
		label.push_color(segmentColor)
		label.add_text(segmentText.to_upper())
		label.pop()
	setAlignment(alignment)

func _textToSegments(value: String) -> Array:
	if _tokenRegex == null:
		_tokenRegex = RegEx.create_from_string(CONTROL_TOKEN_PATTERN)
	var segments := []
	var last := 0
	for found in _tokenRegex.search_all(value):
		if found.get_start() > last:
			segments.append({
				"text": value.substr(last, found.get_start() - last),
				"color": fontColor,
			})
		segments.append({"text": found.get_string(), "color": controlColor})
		last = found.get_end()
	if last < value.length():
		segments.append({"text": value.substr(last), "color": fontColor})
	return segments

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
