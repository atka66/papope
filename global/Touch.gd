extends Node
## Mobile/touch mode: capability detection, the stick state gameplay reads and
## the synthetic action taps the overlay emits. The on-screen controls live in
## objects/system/touch/TouchControls.tscn, instantiated here so they survive
## scene changes.

## Left stick, 0..1. Zeroed when the finger lifts.
var move: Vector2 = Vector2.ZERO
## Right stick, 0..1. Lifting the finger resets it to zero (no aim): the knob
## snaps back and Player falls back to its default right facing.
var aim: Vector2 = Vector2.ZERO
var aim_used: bool = false
## True while the overlay is driving players (lobby or a running map; the
## post-game has no local player bodies, so it does not matter there).
var player_active: bool = false
var overlay_visible: bool = false

var mobile_mode: bool = false

var _fullscreen_requested: bool = false

func _ready() -> void:
	mobile_mode = _detect_mobile()
	if mobile_mode:
		# Mark the touch aim as active so mouse/pad aiming cannot sneak in via
		# kbAimActive. The direction itself starts neutral, like a resting
		# stick; Player falls back to its default right facing.
		aim_used = true
		add_child(Res.TouchControlsObject.instantiate())

func _input(event: InputEvent) -> void:
	# Browsers only allow fullscreen from a user gesture, so the first touch is
	# the only chance. Failures (iOS) are ignored.
	if mobile_mode and not _fullscreen_requested \
		and event is InputEventScreenTouch and event.pressed:
		request_fullscreen_landscape()

func _detect_mobile() -> bool:
	var forced := _touch_override()
	if forced != "":
		return forced == "1"
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		return true
	# Web only counts a coarse primary pointer: a touchscreen laptop still
	# reports a fine pointer (mouse/trackpad) and keeps the desktop flow.
	return OS.has_feature("web") and _web_is_touch()

## --touch (or --touch=0/1) as a user arg, and ?touch=0/1 on web. The override
## wins over detection both ways, so a touchscreen laptop can opt out and a
## desktop can preview the overlay.
func _touch_override() -> String:
	for arg in OS.get_cmdline_user_args() + OS.get_cmdline_args():
		if arg == "--touch":
			return "1"
		if arg.begins_with("--touch="):
			return arg.substr("--touch=".length())
	if OS.has_feature("web"):
		var value = JavaScriptBridge.eval(
			"new URLSearchParams(window.location.search).get('touch')")
		if value != null:
			return str(value)
	return ""

func _web_is_touch() -> bool:
	var coarse = JavaScriptBridge.eval(
		"window.matchMedia ? window.matchMedia('(pointer: coarse)').matches : false")
	if coarse == null:
		# No matchMedia: older browsers, fall back to raw touch points.
		return _web_touch_points() > 0
	return bool(coarse)

func _web_touch_points() -> int:
	var value = JavaScriptBridge.eval("(navigator.maxTouchPoints || 0)")
	if value == null:
		return 0
	return int(value)

## Touch devices have no real mouse: every mouse event is either the click the
## browser fakes from a touch or noise, and the overlay is the only input path.
func ignores_mouse(event: InputEvent) -> bool:
	return mobile_mode and event is InputEventMouse

## Fire an existing input action from an overlay button, so gameplay keeps a
## single input path (pad, keyboard and touch all look the same downstream).
func tap_action(action: StringName) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	down.device = -1
	Input.parse_input_event(down)
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	up.device = -1
	Input.parse_input_event(up)

## Best effort: request fullscreen and lock landscape. Called from the first
## touch so the browser still sees a user gesture.
func request_fullscreen_landscape() -> void:
	if _fullscreen_requested or not OS.has_feature("web"):
		return
	_fullscreen_requested = true
	JavaScriptBridge.eval("""
		(function () {
			var el = document.documentElement;
			try {
				var request = el.requestFullscreen || el.webkitRequestFullscreen;
				if (request) {
					var p = request.call(el);
					if (p && p.catch) p.catch(function () {});
				}
			} catch (e) {}
			try {
				if (screen.orientation && screen.orientation.lock)
					screen.orientation.lock('landscape').catch(function () {});
			} catch (e) {}
		})();
	""")
