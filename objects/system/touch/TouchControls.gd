extends Control
## On-screen twin-stick controls for touch devices. Visible in the lobby, maps,
## cards draft and post-game; each control emits one of the existing input
## actions, so those scenes need no touch-specific code.
##
## Raw touch events are handled here (not per-button Controls) so both sticks
## and all buttons can be held at once and each finger keeps its own role.

enum Zone { NONE, MOVE, AIM, USE, DASH, EXIT }

const STICK_RADIUS := 95.0
const KNOB_RADIUS := 42.0
const BUTTON_RADIUS := 60.0
const EXIT_RADIUS := 38.0
const DEADZONE := 0.12

const MOVE_CENTER := Vector2(300, 585)
const AIM_CENTER := Vector2(1040, 585)
const USE_CENTER := Vector2(150, 190)
const DASH_CENTER := Vector2(1210, 190)
const EXIT_CENTER := Vector2(680, 96)

var _owner_by_touch: Dictionary = {} # touch index -> Zone
var _pressed: Dictionary = {} # Zone -> true while held
var _aim_knob: Vector2 = Vector2.ZERO # live deflection while the aim finger is down
var _scene: Node = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _scene:
		_scene = scene
		_reset()
	var shown := _should_show()
	visible = shown
	Touch.overlay_visible = shown
	Touch.player_active = shown
	if not shown:
		_reset()
	queue_redraw()

func _should_show() -> bool:
	if not Touch.mobile_mode:
		return false
	var scene := get_tree().current_scene
	if scene == null:
		return false
	if scene.name == "Lobby" or scene.name == "PostGame":
		return true
	return _is_map_scene()

func _is_map_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.get_node_or_null("MapController") != null

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		var zone := _zone_at(event.position)
		if event.pressed:
			if zone == Zone.NONE:
				return
			_owner_by_touch[event.index] = zone
			_pressed[zone] = true
			_on_press(zone, event.position)
		elif not _release(event.index):
			return # not our touch: leave menu targets their release
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var zone: int = _owner_by_touch.get(event.index, Zone.NONE)
		if zone == Zone.MOVE:
			Touch.move = _stick_vector(event.position, MOVE_CENTER)
		elif zone == Zone.AIM:
			var vector := _stick_vector(event.position, AIM_CENTER)
			_aim_knob = vector
			Touch.aim_used = true
			if vector != Vector2.ZERO:
				Touch.aim = vector
		else:
			return
		get_viewport().set_input_as_handled()

func _on_press(zone: int, position: Vector2) -> void:
	match zone:
		Zone.MOVE:
			Touch.move = _stick_vector(position, MOVE_CENTER)
		Zone.AIM:
			Touch.aim_used = true
			var vector := _stick_vector(position, AIM_CENTER)
			_aim_knob = vector
			if vector != Vector2.ZERO:
				Touch.aim = vector
		Zone.USE:
			Touch.tap_action("game_use")
		Zone.DASH:
			Touch.tap_action("game_dash")
		Zone.EXIT:
			Touch.tap_action("game_exit")

func _release(index: int) -> bool:
	var zone: int = _owner_by_touch.get(index, Zone.NONE)
	if zone == Zone.NONE:
		return false
	_owner_by_touch.erase(index)
	_pressed.erase(zone)
	if zone == Zone.MOVE:
		Touch.move = Vector2.ZERO
	elif zone == Zone.AIM:
		# Snap the knob back and drop the live aim to neutral.
		_aim_knob = Vector2.ZERO
		Touch.aim = Vector2.ZERO
	return true

func _reset() -> void:
	_owner_by_touch.clear()
	_pressed.clear()
	_aim_knob = Vector2.ZERO
	Touch.move = Vector2.ZERO
	Touch.aim = Vector2.ZERO

func _zone_at(position: Vector2) -> int:
	if position.distance_to(EXIT_CENTER) <= EXIT_RADIUS:
		return Zone.EXIT
	if position.distance_to(USE_CENTER) <= BUTTON_RADIUS:
		return Zone.USE
	if position.distance_to(DASH_CENTER) <= BUTTON_RADIUS:
		return Zone.DASH
	if position.distance_to(MOVE_CENTER) <= STICK_RADIUS:
		return Zone.MOVE
	if position.distance_to(AIM_CENTER) <= STICK_RADIUS:
		return Zone.AIM
	return Zone.NONE

func _stick_vector(position: Vector2, center: Vector2) -> Vector2:
	var offset := (position - center) / STICK_RADIUS
	if offset.length() > 1.0:
		offset = offset.normalized()
	if offset.length() < DEADZONE:
		return Vector2.ZERO
	return offset

func _draw() -> void:
	if not visible:
		return
	_draw_stick(MOVE_CENTER, Touch.move)
	_draw_stick(AIM_CENTER, _aim_knob)
	_draw_button(USE_CENTER, BUTTON_RADIUS, "use", _pressed.has(Zone.USE))
	_draw_button(DASH_CENTER, BUTTON_RADIUS, "dash", _pressed.has(Zone.DASH))
	_draw_button(EXIT_CENTER, EXIT_RADIUS, "exit", _pressed.has(Zone.EXIT))

func _draw_stick(center: Vector2, value: Vector2) -> void:
	draw_circle(center, STICK_RADIUS, Color(1, 1, 1, 0.07))
	draw_arc(center, STICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 2.0)
	var knob := center + value * STICK_RADIUS
	draw_circle(knob, KNOB_RADIUS, Color(1, 1, 1, 0.20))
	draw_arc(knob, KNOB_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.45), 2.0)

func _draw_button(center: Vector2, radius: float, label: String, pressed: bool) -> void:
	draw_circle(center, radius, Color(1, 1, 1, 0.32 if pressed else 0.14))
	draw_arc(center, radius, 0.0, TAU, 40, Color(1, 1, 1, 0.5), 2.0)
	var font := ThemeDB.fallback_font
	var font_size := 18
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, center + Vector2(-text_size.x * 0.5, font_size * 0.35), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 1, 1, 0.85))
