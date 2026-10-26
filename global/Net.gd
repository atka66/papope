extends Node
## Online multiplayer autoload (relay transport).
## Every peer opens an outbound WebSocket to the relay room; the room creator
## (slot 0) is the game authority (isHost): it simulates, owns lobby/match
## state and broadcasts. Guests send inputs + action requests; the host
## executes them and rebroadcasts. Offline path is untouched: every public
## function no-ops unless isOnline.

signal hosted
signal joined
signal join_failed(reason: String)
signal lobby_updated

const MAX_SLOTS := 4
const STATE_RATE := 0.05
const GHOST_RATE := 0.1
const JOIN_TIMEOUT := 10.0
const HEARTBEAT_RATE := 15.0
const HOST_TIMEOUT := 6.0
const PHASE_RATE := 2.0
const PHASE_GRACE := 1.5
const RELAY_VERSION := "1"

var isOnline := false
var isHost := false
var localSlot := -1
var roomCode := ""
var remoteInputs: Dictionary = {} # slot -> [move: Vector2, aim: Vector2]
var clientNonce := 0 # guest hello id, matched by the host's welcome
var slotByNonce: Dictionary = {} # nonce -> slot (host side)
var ws: WebSocketPeer = null

var _wsWasOpen := false
var _wasJoined := false
var _lastHostMsg := -1.0
var _joinTimer: SceneTreeTimer = null
var _beatAccum := 0.0
var _phaseAccum := 0.0
var _phaseSince := -1.0
# Draft messages that landed before this peer's perk overlay existed (slow map
# load); drained by PerkDraft.open() once the overlay is in the tree.
var _pending_perk_reveals: Dictionary = {} # slot -> perk
var _pending_perk_picks: Dictionary = {} # slot -> perks

func _ready() -> void:
	randomize()

func _process(delta: float) -> void:
	if ws == null:
		return
	ws.poll()
	var st := ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN:
		if not _wsWasOpen:
			_wsWasOpen = true
			_on_transport_open()
		while ws != null and ws.get_available_packet_count() > 0:
			var parsed = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			if parsed is Dictionary:
				_handle_envelope(parsed)
	elif st == WebSocketPeer.STATE_CLOSED or st == WebSocketPeer.STATE_CLOSING:
		if isOnline:
			var had := _wasJoined
			var wasHost := isHost
			if had and not wasHost:
				_end_session("connection lost")
			else:
				leave()
				if not had:
					emit_signal("join_failed", "lost relay connection")
	# Host lock advertisement: the list learns our match state from these.
	if isOnline and isHost and not roomCode.is_empty():
		_beatAccum += delta
		if _beatAccum >= HEARTBEAT_RATE:
			_beatAccum = 0.0
			send_heartbeat()
	# Host phase ping: lobby and map snapshots carry the phase already, this
	# only keeps a steady host voice where nothing else is pushed on a
	# schedule (post-game podium). Guests read it like any other host frame.
	if isOnline and isHost:
		_phaseAccum += delta
		if _phaseAccum >= PHASE_RATE:
			_phaseAccum = 0.0
			_send("phase", {"phase": _phase_tag()})
	# Guest watchdog: the host speaks at least every PHASE_RATE seconds in
	# every scene, so a silent host means the session is dead even if the
	# socket stayed open (relay kept it, no bye arrived).
	if isOnline and not isHost and _wasJoined:
		var now := Time.get_ticks_msec() / 1000.0
		if _lastHostMsg >= 0.0 and now - _lastHostMsg > HOST_TIMEOUT:
			_end_session("host left")

func leave_to_menu() -> void:
	# Voluntary exit: this peer is done with the room. Host -> room closes,
	# guest -> host drops the slot in a lobby or ends the session elsewhere.
	_end_session("")

func in_session() -> bool:
	# True once the relay actually put us in a room (false while connecting).
	return isOnline and _wasJoined

func _end_session(notice: String) -> void:
	# The one place a session ends for this peer: local quit, host gone, or a
	# peer lost outside the lobby. Everyone lands on the mode select.
	Global.sessionNotice = notice
	leave()
	var scene := get_tree().current_scene
	if scene != null and scene.name != "MainMenu":
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ------------------------------------------------------------------ config

func relay_base() -> String:
	var custom := get_user_relay_url()
	if not custom.is_empty():
		return custom.trim_suffix("/")
	var env := OS.get_environment("PAPOPE_RELAY_URL").strip_edges()
	if not env.is_empty():
		return env.trim_suffix("/")
	return str(ProjectSettings.get_setting("papope/relay_url", "ws://localhost:8080")).strip_edges().trim_suffix("/")

const USER_RELAY_PATH := "user://relay.cfg"

func get_user_relay_url() -> String:
	# In-game override from the online panel (persists per machine, never in git).
	var cfg := ConfigFile.new()
	if cfg.load(USER_RELAY_PATH) != OK:
		return ""
	return str(cfg.get_value("relay", "url", "")).strip_edges()

func set_user_relay_url(url: String) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("relay", "url", url.strip_edges())
	cfg.save(USER_RELAY_PATH)

func clear_user_relay_url() -> void:
	if FileAccess.file_exists(USER_RELAY_PATH):
		DirAccess.remove_absolute(USER_RELAY_PATH)

func rest_base() -> String:
	var base := relay_base()
	if base.begins_with("wss://"):
		return "https://" + base.substr(6)
	if base.begins_with("ws://"):
		return "http://" + base.substr(5)
	return base

# ------------------------------------------------------------------ lifecycle

func host(unlisted: bool = false) -> void:
	leave()
	isOnline = true
	isHost = true
	localSlot = 0
	remoteInputs.clear()
	slotByNonce.clear()
	_reset_lobby_state()
	var code := await _rest_create_room(unlisted)
	if not isOnline:
		return # backed out while creating
	if code.is_empty():
		leave()
		emit_signal("join_failed", "could not create room (relay offline?)")
		return
	roomCode = code
	_ws_connect()

func join(codeText: String) -> void:
	leave()
	var code := codeText.strip_edges().to_upper()
	if code.length() != 6:
		emit_signal("join_failed", "room code is 6 numbers")
		return
	isOnline = true
	isHost = false
	localSlot = -1
	roomCode = code
	clientNonce = randi()
	_wasJoined = false
	_joinTimer = get_tree().create_timer(JOIN_TIMEOUT)
	_joinTimer.timeout.connect(_on_join_timeout)
	_ws_connect()

func leave() -> void:
	if isOnline and ws != null and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		# Say farewell ourselves instead of relying on the socket dropping:
		# the relay's own bye only fires once the peer really disconnects and
		# it carries -1 for a peer that never sent a frame, which a host
		# ignores. Best effort - an unflushed frame just falls back to that.
		_send("bye", {})
		ws.poll()
	if isHost and not roomCode.is_empty():
		_rest_delete_room(roomCode)
	if ws != null:
		ws.close()
		ws = null
	isOnline = false
	isHost = false
	localSlot = -1
	roomCode = ""
	remoteInputs.clear()
	slotByNonce.clear()
	_wsWasOpen = false
	_wasJoined = false
	_lastHostMsg = -1.0
	_phaseSince = -1.0
	_phaseAccum = 0.0
	_pending_perk_reveals.clear()
	_pending_perk_picks.clear()
	# Restore offline connection flags from real hardware.
	var joypads := Input.get_connected_joypads()
	for i in range(MAX_SLOTS):
		Global.playersConnected[i] = joypads.has(i)
		if not Global.playersConnected[i]:
			Global.playersJoined[i] = false

func _ws_connect() -> void:
	ws = WebSocketPeer.new()
	_wsWasOpen = false
	var err := ws.connect_to_url(relay_base() + "/room/" + roomCode)
	if err != OK:
		leave()
		emit_signal("join_failed", "could not reach relay")

func _on_transport_open() -> void:
	if not isOnline:
		return
	if isHost:
		_wasJoined = true
		push_lobby()
		emit_signal("hosted")
	else:
		_send("hello", {"nonce": clientNonce})

func _on_join_timeout() -> void:
	if isOnline and not isHost and not _wasJoined:
		leave()
		emit_signal("join_failed", "timed out (relay unreachable?)")

# ------------------------------------------------------------------ REST (lobby service)

func _rest_create_room(unlisted: bool) -> String:
	var http := HTTPRequest.new()
	add_child(http)
	var err := http.request(rest_base() + "/v1/rooms", ["Content-Type: application/json"],
		HTTPClient.METHOD_POST, JSON.stringify({"version": RELAY_VERSION, "unlisted": unlisted}))
	if err != OK:
		http.queue_free()
		return ""
	var resp: Array = await http.request_completed
	http.queue_free()
	if int(resp[1]) != 200:
		return ""
	var parsed = JSON.parse_string((resp[3] as PackedByteArray).get_string_from_utf8())
	if parsed is Dictionary:
		return str(parsed.get("code", ""))
	return ""

func rest_list_rooms() -> Array:
	var rooms: Array = []
	var http := HTTPRequest.new()
	add_child(http)
	var err := http.request(rest_base() + "/v1/rooms?version=" + RELAY_VERSION)
	if err != OK:
		http.queue_free()
		return rooms
	var resp: Array = await http.request_completed
	http.queue_free()
	if int(resp[1]) != 200:
		return rooms
	var parsed = JSON.parse_string((resp[3] as PackedByteArray).get_string_from_utf8())
	if parsed is Array:
		rooms = parsed
	return rooms

func send_heartbeat() -> void:
	# Lock advertisement (and room liveness) for the room list.
	if not isOnline or not isHost or roomCode.is_empty():
		return
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(http.queue_free)
	http.request(rest_base() + "/v1/rooms/" + roomCode + "/heartbeat",
		["Content-Type: application/json"], HTTPClient.METHOD_POST,
		JSON.stringify({"locked": is_match_locked()}))

func _rest_delete_room(code: String) -> void:
	# Fire-and-forget: no orphaned listing if we leave cleanly.
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(http.queue_free)
	http.request(rest_base() + "/v1/rooms/" + code, [], HTTPClient.METHOD_DELETE)

# ------------------------------------------------------------------ host helpers

func find_nearest(group: String, pos: Vector2, radius: float):
	var best = null
	var bestDist := radius
	for node in get_tree().get_nodes_in_group(group):
		if node == null or not is_instance_valid(node):
			continue
		if node.is_queued_for_deletion():
			continue
		var d: float = (node as Node2D).global_position.distance_to(pos)
		if d < bestDist:
			bestDist = d
			best = node
	return best

func first_in_group(group: String):
	for node in get_tree().get_nodes_in_group(group):
		if is_instance_valid(node):
			return node
	return null

func advance_match() -> void:
	if not isOnline:
		Global.goToMap()
		return
	if isHost:
		host_start_match()
	# clients wait for the host broadcast

func _reset_lobby_state() -> void:
	Global.playersConnected = [true, false, false, false]
	Global.playersJoined = [true, false, false, false]
	Global.playersPoints = [0, 0, 0, 0]
	Global.playersSkin = [0, 1, 2, 3]
	Global.playersTeam = [0, 1, 2, 3]
	Global.playersKills = [0, 0, 0, 0]
	Global.playersCrowned = [false, false, false, false]
	Global.playersAchievements = [[], [], [], []]
	Global.playersPerks = [[], [], [], []]
	Global.initPlayerStats()

func push_lobby() -> void:
	if not isOnline or not isHost:
		return
	_send("lobby", {
		"connected": Global.playersConnected.duplicate(),
		"joined": Global.playersJoined.duplicate(),
		"team": Global.playersTeam.duplicate(),
		"skin": Global.playersSkin.duplicate(),
		"options": Global.optionsSelected.duplicate(),
		"points": Global.playersPoints.duplicate(),
	})
	# The relay never echoes to the sender, so without this the host's own
	# Lobby would never spawn previews for late joiners (guests learn
	# through the broadcast above). No listeners outside the lobby: harmless.
	emit_signal("lobby_updated")

func begin_countdown() -> void:
	if not isOnline or not isHost:
		return
	_do_countdown()
	_send("countdown", {})
	send_heartbeat()

func cancel_countdown() -> void:
	if not isOnline or not isHost:
		return
	_undo_countdown()
	_send("undo_countdown", {})
	send_heartbeat()

func host_start_match() -> void:
	# Called on the host when a round should begin (lobby countdown or banner).
	if not isOnline or not isHost:
		return
	if Global.getWinnerTeamByScore() >= 0:
		# Podium data is final here: pre-derive post-match achievements so the
		# transmitted lists render identically on all screens.
		for i in range(4):
			if Global.playersJoined[i]:
				Global.finalizeAchievements(i)
		_do_enter_postgame(Global.playersAchievements.duplicate(true),
			_stats_to_rows(), Global.playersKills.duplicate())
		_send("enter_postgame", {
			"achi": _nested_ints(Global.playersAchievements),
			"stats": _stats_to_rows(),
			"kills": _ints(Global.playersKills),
		})
		send_heartbeat()
		return
	var mapName := "hell"
	var idx: int = Global.optionsSelected["map"]
	if idx == 0:
		idx = randi() % (Global.options["map"].size() - 1) + 1
	mapName = Global.options["map"][idx]
	Global.matchSeed = randi()
	_do_enter_map(mapName, Global.playersMaxHp.duplicate(), Global.playersPoints.duplicate(), Global.matchSeed)
	_send("enter_map", {
		"map": mapName,
		"maxHp": _ints(Global.playersMaxHp),
		"points": _ints(Global.playersPoints),
		"seed": Global.matchSeed,
	})
	send_heartbeat()

func to_lobby() -> void:
	if not isOnline or not isHost:
		return
	_do_go_lobby()
	_send("go_lobby", {})
	send_heartbeat()

func send_bg_frame(frame: int, replay: bool) -> void:
	if not isOnline or not isHost:
		return
	_send("bg", {"frame": frame, "replay": replay})

func send_input(slot: int, moveVec: Vector2, aimVec: Vector2) -> void:
	if not isOnline:
		return
	if isHost:
		_apply_input(slot, moveVec, aimVec)
	else:
		_send("input", {"slot": slot, "move": _v2a(moveVec), "aim": _v2a(aimVec)})

func push_state(states: Array) -> void:
	if not isOnline or not isHost:
		return
	_send("state", {"states": _enc_states(states), "phase": _phase_tag()})

func notify_action(slot: int, action: String, aimVec: Vector2, moveVec: Vector2) -> void:
	if not isOnline or not isHost:
		return
	_exec_action(slot, action, aimVec, moveVec)
	_send("action", {"slot": slot, "action": action, "aim": _v2a(aimVec), "move": _v2a(moveVec)})

func request_action(slot: int, action: String, aimVec: Vector2, moveVec: Vector2) -> void:
	# Guest -> host: the host executes, then rebroadcasts to everyone.
	if not isOnline:
		return
	if isHost:
		notify_action(slot, action, aimVec, moveVec)
	else:
		_send("action", {"slot": slot, "action": action, "aim": _v2a(aimVec), "move": _v2a(moveVec)})

func notify_fall(slot: int, isLava: bool) -> void:
	# Guest copy fell into a pit the host copy did not; host applies it.
	if not isOnline or isHost:
		return
	_send("fall", {"slot": slot, "lava": isLava})

func request_lobby_change(kind: String, slot: int, value) -> void:
	if not isOnline:
		return
	if isHost:
		_apply_lobby_change(kind, slot, value)
	else:
		_send("lobby_req", {"reqkind": kind, "slot": slot, "value": value})

func submit_perks(slot: int, perks: Array) -> void:
	if not isOnline or isHost:
		return
	_send("perks", {"slot": slot, "perks": perks.duplicate()})

func push_perk_reveal(slot: int, perk: int) -> void:
	# A player revealed their card. Host rebroadcasts; a guest's copy is caught
	# by the host and echoed to everyone (the relay never echoes to the sender).
	if not isOnline:
		return
	_send("perk_reveal", {"slot": slot, "perk": perk})

func broadcast_perks(slot: int, perks: Array) -> void:
	# Host finish: announce the host's own picks (submit_perks only fires for
	# guests). Per-slot so a still-drafting peer is never marked done.
	if not isOnline or not isHost:
		return
	_send("perk_pick", {"slot": slot, "perks": perks.duplicate()})

func request_disco() -> void:
	# Late-loading guest missed the current cycle broadcast; host sends it back.
	if not isOnline or isHost:
		return
	_send("disco_req", {})

func request_resync() -> void:
	# Guest -> host: "which phase are we in?". Travel messages (enter_map,
	# enter_postgame, go_lobby, bye) are sent once and the relay drops frames
	# for a stalled peer, so one lost frame would strand this guest in a room
	# the others have left. The host re-announces its phase instead.
	if not isOnline or isHost:
		return
	_send("resync", {})

func current_phase() -> String:
	# Coarse session phase, shared as a tag on host traffic. Guests compare it
	# against their own scene to notice a missed travel message.
	var scene := get_tree().current_scene
	if scene == null:
		return ""
	var name := str(scene.name)
	if name == "Lobby":
		return "lobby"
	if name.begins_with("Map"):
		return "map"
	if name == "PostGame":
		return "postgame"
	return ""

func _phase_tag() -> String:
	# Wire tag: the phase, plus the round seed inside a map so a guest that
	# missed a round change reads it as a mismatch too (seed rolls per round).
	var phase := current_phase()
	if phase == "map":
		return phase + ":" + str(Global.matchSeed)
	return phase

func _note_host_phase(payload: Dictionary) -> void:
	if not isOnline or isHost or not _wasJoined:
		return
	var hostTag := str(payload.get("phase", ""))
	var now := Time.get_ticks_msec() / 1000.0
	if hostTag == "" or hostTag == _phase_tag():
		_phaseSince = -1.0
		return
	if _phaseSince < 0.0:
		_phaseSince = now # mismatch: give a travel message in flight time
	elif now - _phaseSince >= PHASE_GRACE:
		_phaseSince = now # hold off again until the answer lands
		request_resync()

func _send_phase_snapshot() -> void:
	# Host answer to a resync. Receivers ignore it when they are already
	# there (or already on their way), so it is safe to send at any time.
	if not isOnline or not isHost:
		return
	match current_phase():
		"map":
			_send("enter_map", {
				"map": Global.selectedMap,
				"maxHp": _ints(Global.playersMaxHp),
				"points": _ints(Global.playersPoints),
				"seed": Global.matchSeed,
			})
		"postgame":
			_send("enter_postgame", {
				"achi": _nested_ints(Global.playersAchievements),
				"stats": _stats_to_rows(),
				"kills": _ints(Global.playersKills),
			})
		"lobby":
			push_lobby()
			_send("countdown" if is_match_locked() else "undo_countdown", {})
			_push_join_state()

# Host-only event broadcasts (callers run under isHost checks already).
func spawn_pwrup(spawnerIdx: int, typeIdx: int) -> void:
	if not isOnline or not isHost:
		return
	_send("spawn_pwrup", {"spawner": spawnerIdx, "type": typeIdx})

func despawn_pwrup(spawnerIdx: int) -> void:
	if not isOnline or not isHost:
		return
	_send("despawn_pwrup", {"spawner": spawnerIdx})

func ghost_event(nodeIdx: int, colorIdx: int = -1) -> void:
	if not isOnline or not isHost:
		return
	_send("ghost_event", {"node": nodeIdx, "color": colorIdx})

func push_ghost(pos: Vector2) -> void:
	if not isOnline or not isHost:
		return
	_send("ghost_pos", {"pos": _v2a(pos)})

func ghost_died() -> void:
	if not isOnline or not isHost:
		return
	_send("ghost_died", {})

func pellet_eaten(pos: Vector2) -> void:
	if not isOnline or not isHost:
		return
	_send("pellet", {"pos": _v2a(pos)})

func car_event(laneName: String, carSpeed: float, paint: int) -> void:
	if not isOnline or not isHost:
		return
	_send("car", {"lane": laneName, "speed": carSpeed, "paint": paint})

func trap_sprung(trapPos: Vector2) -> void:
	if not isOnline or not isHost:
		return
	_send("trap", {"pos": _v2a(trapPos)})

func cactus_hit(cactusPos: Vector2, sound: bool = true) -> void:
	if not isOnline or not isHost:
		return
	_send("cactus", {"pos": _v2a(cactusPos), "sound": sound})

func disco_hit(wallPos: Vector2) -> void:
	# Nightclub neon ring: the host authors the flash, everyone replays it.
	if not isOnline or not isHost:
		return
	_send("discowall", {"pos": _v2a(wallPos)})

func dynamite_blast(pos: Vector2, originSlot: int) -> void:
	if not isOnline or not isHost:
		return
	_send("dynamite", {"pos": _v2a(pos), "slot": originSlot})

func damage_number(text: String, pos: Vector2, color: Color, size: int) -> void:
	# Cosmetic: best effort (a dropped number beats any stall).
	if not isOnline or not isHost:
		return
	_send("damage", {"text": text, "pos": _v2a(pos), "color": _c2a(color), "size": size})

func disco_cycle(idx: int, cycleSeed: int) -> void:
	if not isOnline or not isHost:
		return
	_send("disco", {"idx": idx, "seed": cycleSeed})

func collision_fx(pos: Vector2, animScale: float, lookPos: Vector2) -> void:
	if not isOnline or not isHost:
		return
	_send("collision", {"pos": _v2a(pos), "scale": animScale, "look": _v2a(lookPos)})

func round_end(aliveTeamId: int, points: Array) -> void:
	if not isOnline or not isHost:
		return
	_send("round_end", {"team": aliveTeamId, "points": _ints(points)})

# ------------------------------------------------------------------ envelope transport

func _send(kind: String, payload: Dictionary = {}) -> void:
	if not isOnline or ws == null:
		return
	if ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	ws.send_text(JSON.stringify({"v": 1, "room": roomCode, "from": localSlot, "kind": kind, "payload": payload}))

func _handle_envelope(env: Dictionary) -> void:
	if not isOnline:
		return
	if int(env.get("v", 1)) != 1:
		return
	var kind := str(env.get("kind", ""))
	var from := int(env.get("from", -1))
	if from == 0:
		_lastHostMsg = Time.get_ticks_msec() / 1000.0
	var payload: Dictionary = {}
	if env.get("payload") is Dictionary:
		payload = env["payload"]
	match kind:
		"bye":
			_on_bye(from)
		"hello":
			if isHost:
				_on_hello(int(payload.get("nonce", 0)))
		"welcome":
			if not isHost:
				_on_welcome(payload)
		"lobby":
			if from == 0:
				_apply_lobby(payload)
		"countdown":
			if from == 0:
				_do_countdown()
		"undo_countdown":
			if from == 0:
				_undo_countdown()
		"enter_map":
			if from == 0:
				_do_enter_map(str(payload.get("map", "hell")), _ints(payload.get("maxHp", [])),
					_ints(payload.get("points", [])), int(payload.get("seed", 123)))
		"enter_postgame":
			if from == 0:
				_do_enter_postgame(_nested_ints(payload.get("achi", [])), _nested_ints(payload.get("stats", [])),
					_ints(payload.get("kills", [])))
		"go_lobby":
			if from == 0:
				_do_go_lobby()
		"state":
			if from == 0:
				_note_host_phase(payload)
				_apply_states(payload.get("states", []))
		"input":
			if isHost:
				_apply_input(int(payload.get("slot", -1)), _a2v(payload.get("move")), _a2v(payload.get("aim")))
		"action":
			if isHost and from != 0:
				# Guest request: execute, then rebroadcast as host truth.
				_exec_action(int(payload.get("slot", -1)), str(payload.get("action", "")),
					_a2v(payload.get("aim")), _a2v(payload.get("move")))
				_send("action", payload)
			elif from == 0:
				_exec_action(int(payload.get("slot", -1)), str(payload.get("action", "")),
					_a2v(payload.get("aim")), _a2v(payload.get("move")))
		"fall":
			if isHost:
				_apply_fall(int(payload.get("slot", -1)), bool(payload.get("lava", false)))
		"lobby_req":
			if isHost:
				_apply_lobby_change(str(payload.get("reqkind", "")), int(payload.get("slot", -1)), payload.get("value"))
		"perks":
			if isHost:
				_apply_perks(int(payload.get("slot", -1)), payload.get("perks", []))
		"perk_reveal":
			if isHost and from != 0:
				# Guest reveal: mirror it locally, then rebroadcast as host truth.
				_apply_perk_reveal(int(payload.get("slot", -1)), int(payload.get("perk", -1)))
				_send("perk_reveal", payload)
			elif from == 0:
				_apply_perk_reveal(int(payload.get("slot", -1)), int(payload.get("perk", -1)))
		"perk_pick":
			if from == 0:
				_apply_perk_pick(int(payload.get("slot", -1)), payload.get("perks", []))
		"disco_req":
			if isHost:
				_push_disco_current()
		"resync":
			if isHost and from != 0:
				# A guest asked where we are: re-announce the phase.
				_send_phase_snapshot()
		"phase":
			if from == 0:
				_note_host_phase(payload)
		"spawn_pwrup":
			if from == 0 and is_map_ready():
				Global.MapControllerNode.spawnNetPwrup(int(payload.get("spawner", -1)), int(payload.get("type", -1)))
		"despawn_pwrup":
			if from == 0 and is_map_ready():
				Global.MapControllerNode.despawnNetPwrup(int(payload.get("spawner", -1)))
		"ghost_event":
			if from == 0 and is_map_ready():
				Global.MapControllerNode.spawnNetGhost(int(payload.get("node", 0)), int(payload.get("color", -1)))
		"ghost_pos":
			if from == 0:
				var ghost = first_in_group("ghosts")
				if ghost != null and ghost.has_method("push_snapshot"):
					ghost.push_snapshot(_a2v(payload.get("pos")))
		"ghost_died":
			if from == 0:
				var ghost = first_in_group("ghosts")
				if ghost != null and ghost.has_method("mirrorDeath"):
					ghost.mirrorDeath()
		"pellet":
			if from == 0:
				var best = find_nearest("pellets", _a2v(payload.get("pos")), 48.0)
				if best != null and best.has_method("consume"):
					best.consume()
		"car":
			if from == 0:
				var scene := get_tree().current_scene
				if scene != null:
					var lane := scene.get_node_or_null(str(payload.get("lane", "")))
					if lane != null and lane.has_method("spawnNetCar"):
						lane.spawnNetCar(float(payload.get("speed", 0.0)), int(payload.get("paint", 0)))
		"trap":
			if from == 0:
				var best = find_nearest("conveyables", _a2v(payload.get("pos")), 200.0)
				if best != null and best.has_method("showSprung"):
					best.showSprung()
		"cactus":
			if from == 0:
				var best = find_nearest("cacti", _a2v(payload.get("pos")), 120.0)
				if best != null:
					best.bounce()
					if bool(payload.get("sound", true)):
						best.pinch()
		"discowall":
			if from == 0:
				var wall = find_nearest("discowalls", _a2v(payload.get("pos")), 8.0)
				if wall != null and wall.has_method("boop"):
					wall.boop()
		"dynamite":
			if from == 0:
				var at := _a2v(payload.get("pos"))
				var best = find_nearest("dynamites", at, 256.0)
				if best != null and is_instance_valid(best):
					best.queue_free()
				var boom = Res.ExplosionAnimObject.instantiate()
				boom.position = at
				boom.originPlayerId = int(payload.get("slot", 0))
				boom.harmful = false
				Global.addToScene(boom)
		"damage":
			if from == 0:
				Global.spawnFallingLabel(str(payload.get("text", "")), _a2v(payload.get("pos")),
					_a2c(payload.get("color")), int(payload.get("size", 2)))
		"disco":
			if from == 0:
				var discoFloor = first_in_group("discofloor")
				if discoFloor != null and discoFloor.has_method("adoptCycle"):
					discoFloor.adoptCycle(int(payload.get("idx", 0)), int(payload.get("seed", 0)))
		"collision":
			if from == 0:
				var anim = Res.CollisionAnimObject.instantiate()
				anim.scale = Vector2(float(payload.get("scale", 1.0)), float(payload.get("scale", 1.0)))
				anim.position = _a2v(payload.get("pos"))
				anim.look_at(_a2v(payload.get("look")))
				Global.addToScene(anim)
		"bg":
			if from == 0:
				var lobby := get_node_or_null("/root/Lobby")
				if lobby != null and lobby.has_method("applyBgFrame"):
					lobby.applyBgFrame(int(payload.get("frame", 0)), bool(payload.get("replay", false)))
		"round_end":
			if from == 0:
				Global.playersPoints = _ints(payload.get("points", []))
				if is_map_ready() and Global.MapControllerNode.has_method("showNetRoundEnd"):
					Global.MapControllerNode.showNetRoundEnd(int(payload.get("team", -1)))

func is_map_ready() -> bool:
	return Global.MapControllerNode != null and is_instance_valid(Global.MapControllerNode)

func is_match_locked() -> bool:
	# Unlocked only while the host idles in the lobby: rounds chain
	# map-to-map with no lobby in between (no unlock window mid-match),
	# a running countdown counts as ongoing, and transitions default
	# to locked.
	if not isOnline or not isHost:
		return false
	var lobby := get_node_or_null("/root/Lobby")
	if lobby == null:
		return true
	return lobby.countdownNode != null

# ------------------------------------------------------------------ hello / welcome / bye

func _on_hello(nonce: int) -> void:
	if slotByNonce.has(nonce):
		# Duplicate hello: resync this guest.
		_send("welcome", {"nonce": nonce, "slot": int(slotByNonce[nonce])})
		push_lobby()
		_push_join_state()
		return
	var slot := -1
	for i in range(MAX_SLOTS):
		if not Global.playersJoined[i]:
			slot = i
			break
	if is_match_locked():
		# Running match: the list flag is advisory, this is enforcement.
		# Covers stale lists, direct code entry, and old clients alike.
		_send("welcome", {"nonce": nonce, "slot": -1, "reason": "match"})
		return
	if slot < 0:
		_send("welcome", {"nonce": nonce, "slot": -1, "reason": "full"})
		return
	slotByNonce[nonce] = slot
	Global.playersConnected[slot] = true
	Global.playersJoined[slot] = true
	Global.playersCrowned[slot] = false
	push_lobby()
	_send("welcome", {"nonce": nonce, "slot": slot})
	_push_join_state()

func _on_welcome(payload: Dictionary) -> void:
	if int(payload.get("nonce", 0)) != clientNonce:
		return
	var slot := int(payload.get("slot", -1))
	if slot < 0:
		leave()
		if str(payload.get("reason", "")) == "match":
			emit_signal("join_failed", "match in progress")
		else:
			emit_signal("join_failed", "room is full")
		return
	localSlot = slot
	_wasJoined = true
	emit_signal("joined")

func _on_bye(from: int) -> void:
	if isHost:
		# A peer that never became a player (failed join, stray probe) must not
		# kill the room. A joined one is normal churn in the lobby and fatal
		# once we are past it (map, postgame, transitions).
		if from <= 0 or from >= MAX_SLOTS or not Global.playersJoined[from]:
			return
		if current_phase() == "lobby":
			_drop_lobby_slot(from)
		else:
			_end_session("player left")
		return
	if from == 0:
		# Game-host gone: session over. Guest-vs-guest byes are ignored here:
		# the host decides whether the room lives on or ends.
		_end_session("host left")

func _drop_lobby_slot(slot: int) -> void:
	# Lobby only: peers come and go and the room lives on. Previews follow via
	# the push_lobby below (Lobby._on_lobby_updated reconciles both ways).
	for nonce in slotByNonce.keys():
		if int(slotByNonce[nonce]) == slot:
			slotByNonce.erase(nonce)
	remoteInputs.erase(slot)
	Global.playersConnected[slot] = false
	Global.playersJoined[slot] = false
	Global.playersCrowned[slot] = false
	if is_match_locked() and (Global.playersJoined.count(true) < 2 or Global.getNumberOfTeams() < 2):
		cancel_countdown()
	push_lobby()

func _push_join_state() -> void:
	# Newcomer paint: 'random' lobby backdrop follows the host frame, and a
	# late loader gets the current disco cycle (both idempotent on guests).
	var lobby := get_node_or_null("/root/Lobby")
	if lobby != null and lobby.has_method("sendBgTo"):
		lobby.sendBgTo()
	_push_disco_current()

func _push_disco_current() -> void:
	var discoFloor = first_in_group("discofloor")
	if discoFloor != null:
		var cur: Array = discoFloor.get("_current")
		if cur.size() == 2 and int(cur[0]) >= 0:
			_send("disco", {"idx": int(cur[0]), "seed": int(cur[1])})

# ------------------------------------------------------------------ local bodies (ran on host, mirrored on guests)

func _do_countdown() -> void:
	var lobby := get_node_or_null("/root/Lobby")
	if lobby != null and lobby.has_method("startCountdown") and lobby.countdownNode == null:
		lobby.startCountdown()

func _undo_countdown() -> void:
	var lobby := get_node_or_null("/root/Lobby")
	if lobby != null and lobby.has_method("stopCountdown") and lobby.countdownNode != null:
		lobby.stopCountdown()

func _do_enter_map(mapName: String, maxHp: Array, points: Array, mapSeed: int = 123) -> void:
	if not isHost and _in_map_named(mapName) and mapSeed == Global.matchSeed:
		return # same round re-announced, not a new one (seed rolls per round)
	# New round: drop any draft message cached for the previous round's overlay.
	_pending_perk_reveals.clear()
	_pending_perk_picks.clear()
	Global.playersMaxHp = maxHp
	Global.playersPoints = points
	Global.matchSeed = mapSeed
	Global.goToMap(mapName)

func _in_map_named(mapName: String) -> bool:
	var scene := get_tree().current_scene
	if scene == null or mapName.is_empty():
		return false
	return str(scene.name).to_lower() == "map" + mapName.to_lower()

func _do_enter_postgame(achi: Array, stats: Array, kills: Array) -> void:
	if achi.size() == 4:
		Global.playersAchievements = achi
	if stats.size() == 4:
		var rebuilt := []
		for row in stats:
			var d := {}
			for k in range((row as Array).size()):
				d[k] = int((row as Array)[k])
			rebuilt.append(d)
		Global.playersStats = rebuilt
	if kills.size() == 4:
		Global.playersKills = kills
	if not isHost and current_phase() == "postgame":
		return # already here: a re-announced phase
	get_tree().change_scene_to_file("res://scenes/PostGame.tscn")

func _do_go_lobby() -> void:
	if not isHost and current_phase() == "lobby":
		return # already here: a re-announced phase
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func _apply_lobby(payload: Dictionary) -> void:
	Global.playersConnected = _bools(payload.get("connected", []))
	Global.playersJoined = _bools(payload.get("joined", []))
	Global.playersTeam = _ints(payload.get("team", []))
	Global.playersSkin = _ints(payload.get("skin", []))
	var opts: Dictionary = {}
	if payload.get("options") is Dictionary:
		opts = payload["options"]
	for key in Global.optionsSelected.keys():
		if opts.has(key):
			Global.optionsSelected[key] = int(opts[key])
	Global.playersPoints = _ints(payload.get("points", []))
	emit_signal("lobby_updated")
	if not isHost and localSlot >= 0 and not _wasJoined:
		_wasJoined = true
		emit_signal("joined")

func _apply_input(slot: int, moveVec: Vector2, aimVec: Vector2) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	remoteInputs[slot] = [moveVec, aimVec]
	var player := Global.getPlayer(slot)
	if player != null:
		player.netMove = moveVec
		player.remoteAim = aimVec
		player.hasRemoteAim = true

func _apply_states(states) -> void:
	if not (states is Array):
		return
	for s in states:
		if not (s is Array) or s.size() < 10:
			continue
		var row := (s as Array).duplicate()
		row[1] = _a2v(row[1])
		row[2] = _a2v(row[2])
		row[8] = _a2v(row[8])
		var player := Global.getPlayer(int(row[0]))
		if player != null and player.has_method("apply_net_state"):
			player.apply_net_state(row)

func _exec_action(slot: int, action: String, aimVec: Vector2, moveVec: Vector2) -> void:
	var player := Global.getPlayer(slot)
	if player == null or not player.alive:
		return
	player.remoteAim = aimVec
	player.hasRemoteAim = true
	match action:
		"use":
			player.useItem()
		"dash":
			player.dash(moveVec)
	player.hasRemoteAim = false

func _apply_fall(slot: int, isLava: bool) -> void:
	var player := Global.getPlayer(slot)
	if player != null and player.alive and not player.isFallingIntoWater:
		player.fallDown(isLava)

func _apply_lobby_change(kind: String, slot: int, value) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	match kind:
		"team":
			Global.playersTeam[slot] = int(value) % 4
		"skin":
			Global.playersSkin[slot] = int(value) % Global.SKIN_COUNT
		"options":
			if value is Array and value.size() == 2:
				var key: String = str(value[0])
				if Global.optionsSelected.has(key):
					Global.optionsSelected[key] = int(value[1])
	push_lobby()

func _apply_perks(slot: int, perks) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	if perks is Array:
		Global.playersPerks[slot] = _ints(perks)
		# Update the host's own overlay for the guest's slot, then rebroadcast.
		_apply_perk_pick(slot, Global.playersPerks[slot])
		_send("perk_pick", {"slot": slot, "perks": Global.playersPerks[slot]})

func _apply_perk_reveal(slot: int, perk: int) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	if perk < 0 or perk >= len(Global.PerkEnum):
		return
	if slot == localSlot:
		return # own draft already revealed locally
	var draft = Global.PerkDraftNode
	if draft == null:
		_pending_perk_reveals[slot] = perk # overlay not up yet (slow load)
		return
	draft.reveal_remote(slot, perk)

func _apply_perk_pick(slot: int, perks) -> void:
	if slot < 0 or slot >= MAX_SLOTS:
		return
	if not (perks is Array):
		return
	if slot == localSlot:
		return # own draft stays authoritative locally
	Global.playersPerks[slot] = _ints(perks)
	var draft = Global.PerkDraftNode
	if draft == null:
		_pending_perk_picks[slot] = Global.playersPerks[slot] # overlay not up yet
		return
	draft.apply_remote_pick(slot, Global.playersPerks[slot])

## Draft messages that arrived before this machine's overlay existed. The draft
## drains these in open() so no slot is left face-down forever.
func take_pending_draft() -> Array:
	var out := [_pending_perk_reveals.duplicate(), _pending_perk_picks.duplicate()]
	_pending_perk_reveals.clear()
	_pending_perk_picks.clear()
	return out

# ------------------------------------------------------------------ payload codecs (JSON turns every number into float)

func _v2a(v: Vector2) -> Array:
	return [v.x, v.y]

func _a2v(a) -> Vector2:
	if a is Array and (a as Array).size() >= 2:
		return Vector2(float(a[0]), float(a[1]))
	return Vector2.ZERO

func _c2a(c: Color) -> Array:
	return [c.r, c.g, c.b, c.a]

func _a2c(a) -> Color:
	if a is Array and (a as Array).size() >= 4:
		return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]))
	return Color.WHITE

func _ints(a) -> Array:
	var out := []
	if a is Array:
		for x in (a as Array):
			out.append(int(x))
	return out

func _bools(a) -> Array:
	var out := []
	if a is Array:
		for x in (a as Array):
			out.append(bool(x))
	return out

func _nested_ints(a) -> Array:
	var out := []
	if a is Array:
		for row in (a as Array):
			out.append(_ints(row))
	return out

func _enc_states(states: Array) -> Array:
	# [slot, pos, vel, hp, alive, itemInt, ammo, shielded, aim, trapped]
	var out := []
	for s in states:
		if not (s is Array) or (s as Array).size() < 10:
			continue
		var row := s as Array
		out.append([int(row[0]), _v2a(row[1]), _v2a(row[2]), row[3], row[4],
			row[5], row[6], row[7], _v2a(row[8]), row[9]])
	return out

func _stats_to_rows() -> Array:
	# Stat dicts have int keys (JSON would stringify them): fixed 10-num rows.
	var out := []
	for i in range(MAX_SLOTS):
		var row := []
		for k in range(10):
			row.append(int(Global.playersStats[i].get(k, 0)))
		out.append(row)
	return out
