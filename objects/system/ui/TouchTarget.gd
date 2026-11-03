extends Control
## Invisible hit area for real touch input only. A physical desktop mouse is
## ignored: Godot tags mouse events emulated from a touchscreen with
## InputEvent.DEVICE_ID_EMULATION, while a real mouse keeps its own device id.

signal tapped()

const TAP_DEDUPE_MS := 120

# Shared across targets: one physical tap produces both an emulated mouse event
# and a touch event, and those two can land on different targets if the first
# one changed the UI.
static var _lastTapMsec := -100000

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_emit_tap()
		accept_event()
		return
	if event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and event.device == InputEvent.DEVICE_ID_EMULATION:
		_emit_tap()
		accept_event()

func _emit_tap() -> void:
	var now := Time.get_ticks_msec()
	if now - _lastTapMsec < TAP_DEDUPE_MS:
		return
	_lastTapMsec = now
	tapped.emit()
