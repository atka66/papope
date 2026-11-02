extends CanvasLayer
## Two-step exit confirmation. Scenes call `request(text)` on an exit press:
## the first press shows the prompt and arms a short window; a second press
## inside that window returns true so the caller can leave. After the window
## lapses the next press re-arms the prompt from scratch.

const HOLD := 1.0
const FADE := 1.0
const WINDOW := HOLD + FADE

var _armedUntil: float = 0.0
var _tween: Tween

@onready var _root: Node2D = $Root
@onready var _label = $Root/Label

func _ready() -> void:
	_root.hide()
	# Informational only: clicks keep reaching the menu underneath.
	$Root/Dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.get_node("Container/Label").mouse_filter = Control.MOUSE_FILTER_IGNORE

func request(text: String) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if now < _armedUntil:
		_armedUntil = 0.0
		_hide()
		return true
	_show(text, now)
	return false

func _show(text: String, now: float) -> void:
	_label.text = text
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_root.modulate.a = 1.0
	_root.show()
	_armedUntil = now + WINDOW
	_tween = create_tween()
	_tween.tween_interval(HOLD)
	_tween.tween_property(_root, "modulate:a", 0.0, FADE)
	_tween.tween_callback(_on_faded)

func _hide() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_root.hide()

func _on_faded() -> void:
	_root.hide()
