extends Control
## On-screen twin-stick controls for touch devices. Visible in the lobby, maps,
## cards draft and post-game; each control emits one of the existing input
## actions, so those scenes need no touch-specific code.
##
## Raw touch events are handled here (not per-button Controls) so both sticks
## and all buttons can be held at once and each finger keeps its own role.
##
## The sticks are floating: pressing anywhere in a zone box spawns the base at
## the touch point and the deflection is measured from there. Each box and its
## hint label is the only affordance; the stick itself is drawn only while a
## finger holds it.

enum Zone { NONE, MOVE, AIM, USE, DASH, EXIT }

const FONT: FontFile = preload("res://fonts/blockbit.ttf")
const FONT_SIZE := 20

const STICK_RADIUS := 95.0
const KNOB_RADIUS := 42.0
const BUTTON_CORNER := 24.0
const BUTTON_FONT_SIZE := 30
const DEADZONE := 0.12

# Layout in the fixed 1360x768 viewport. Buttons and stick boxes share one line
# with equal 100 px gaps between them, and the buttons run out to the screen
# edges (20 px margins) and down to the bottom:
#   use 20..210 | move 310..630 | aim 730..1050 | dash 1150..1340
# so each thumb gets its own hit area next to its button and the middle of the
# screen stays free. Exit sits in the gap between the lobby title (ends at
# x 856) and the room code (starts at x 1156), the only spot on screen that
# nothing else claims - map HUDs are in the screen's corners and the post-game
# posters' content is centred in their columns.
const USE_BUTTON := Rect2(20.0, 515.0, 190.0, 233.0)
const DASH_BUTTON := Rect2(1150.0, 515.0, 190.0, 233.0)
const EXIT_BUTTON := Rect2(925.0, 20.0, 150.0, 93.0)
const MOVE_ZONE := Rect2(310.0, 465.0, 320.0, 240.0)
const AIM_ZONE := Rect2(730.0, 465.0, 320.0, 240.0)

var _owner_by_touch: Dictionary = {} # touch index -> Zone
var _owner_by_zone: Dictionary = {} # Zone -> touch index of the current grab
var _pressed: Dictionary = {} # Zone -> true while held
var _move_origin: Vector2 = Vector2.ZERO # base of the current grab
var _aim_origin: Vector2 = Vector2.ZERO
var _aim_knob: Vector2 = Vector2.ZERO # live deflection while the aim finger is down
var _scene: Node = null
var _button_normal: StyleBoxFlat
var _button_pressed: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_button_normal = _make_button_style(0.14)
	_button_pressed = _make_button_style(0.32)

func _make_button_style(fill_alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, fill_alpha)
	style.border_color = Color(1, 1, 1, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(int(BUTTON_CORNER))
	return style

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
			# A fresh grab takes the control over (and re-anchors a stick), so a
			# touch whose release got lost can never leave it stuck held.
			_owner_by_touch[event.index] = zone
			_owner_by_zone[zone] = event.index
			_pressed[zone] = true
			_on_press(zone, event.position)
		elif not _release(event.index):
			return # not our touch: leave menu targets their release
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var zone: int = _owner_by_touch.get(event.index, Zone.NONE)
		# Ignore drags from a finger that lost the control to a newer grab.
		if zone == Zone.NONE or _owner_by_zone.get(zone, -1) != event.index:
			return
		if zone == Zone.MOVE:
			Touch.move = _stick_vector(event.position, _move_origin)
		elif zone == Zone.AIM:
			var vector := _stick_vector(event.position, _aim_origin)
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
			_move_origin = position
			Touch.move = Vector2.ZERO # the press point is the origin
		Zone.AIM:
			_aim_origin = position
			Touch.aim_used = true
			_aim_knob = Vector2.ZERO
			Touch.aim = Vector2.ZERO
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
	# A newer grab owns the control now: this lift must not cancel that finger.
	if _owner_by_zone.get(zone, -1) != index:
		return true
	_owner_by_zone.erase(zone)
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
	_owner_by_zone.clear()
	_pressed.clear()
	_aim_knob = Vector2.ZERO
	Touch.move = Vector2.ZERO
	Touch.aim = Vector2.ZERO

func _zone_at(position: Vector2) -> int:
	# Buttons win over the boxes, so their hit areas stay exact.
	if EXIT_BUTTON.has_point(position):
		return Zone.EXIT
	if USE_BUTTON.has_point(position):
		return Zone.USE
	if DASH_BUTTON.has_point(position):
		return Zone.DASH
	if MOVE_ZONE.has_point(position):
		return Zone.MOVE
	if AIM_ZONE.has_point(position):
		return Zone.AIM
	return Zone.NONE

func _stick_vector(position: Vector2, origin: Vector2) -> Vector2:
	var offset := (position - origin) / STICK_RADIUS
	if offset.length() > 1.0:
		offset = offset.normalized()
	if offset.length() < DEADZONE:
		return Vector2.ZERO
	return offset

func _draw() -> void:
	if not visible:
		return
	_draw_zone(MOVE_ZONE, "MOVE")
	_draw_zone(AIM_ZONE, "AIM")
	# A stick only shows up while it is held; the boxes are the resting cue.
	if _pressed.has(Zone.MOVE):
		_draw_stick(_move_origin, Touch.move)
	if _pressed.has(Zone.AIM):
		_draw_stick(_aim_origin, _aim_knob)
	_draw_button(USE_BUTTON, "USE", _pressed.has(Zone.USE))
	_draw_button(DASH_BUTTON, "DASH", _pressed.has(Zone.DASH))
	_draw_button(EXIT_BUTTON, "EXIT", _pressed.has(Zone.EXIT))

## A stick's hit area, drawn to match `MOVE_ZONE`/`AIM_ZONE` exactly, with its
## hint label under the top edge (the thumb covers the middle on a press).
func _draw_zone(rect: Rect2, label: String) -> void:
	draw_rect(rect, Color(1, 1, 1, 0.06))
	draw_rect(rect, Color(1, 1, 1, 0.22), false, 2.0)
	var text_size := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var baseline := rect.position.y + 10.0 + FONT.get_ascent(FONT_SIZE)
	draw_string(FONT,
		Vector2(rect.position.x + (rect.size.x - text_size.x) * 0.5, baseline),
		label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(1, 1, 1, 0.6))

func _draw_stick(center: Vector2, value: Vector2) -> void:
	draw_circle(center, STICK_RADIUS, Color(1, 1, 1, 0.07))
	draw_arc(center, STICK_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.25), 2.0)
	var knob := center + value * STICK_RADIUS
	draw_circle(knob, KNOB_RADIUS, Color(1, 1, 1, 0.20))
	draw_arc(knob, KNOB_RADIUS, 0.0, TAU, 32, Color(1, 1, 1, 0.45), 2.0)

func _draw_button(rect: Rect2, label: String, pressed: bool) -> void:
	var style := _button_pressed if pressed else _button_normal
	draw_style_box(style, rect)
	_draw_label(rect.get_center(), label, BUTTON_FONT_SIZE, Color(1, 1, 1, 0.85))

## Draws `label` horizontally and vertically centred on `center`, using the
## font's own metrics (blockbit's ascent is tall).
func _draw_label(center: Vector2, label: String, font_size: int, color: Color) -> void:
	var text_size := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := center.y + (FONT.get_ascent(font_size) - FONT.get_descent(font_size)) * 0.5
	draw_string(FONT, Vector2(center.x - text_size.x * 0.5, baseline), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
