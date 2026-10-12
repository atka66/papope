extends Node
## Online multiplayer autoload (v1: desktop ENet listen-server, join-by-IP).
## Host (peer 1) is authoritative: simulates, owns lobby/match state, broadcasts.
## Clients send inputs + action requests; states flow back via unreliable RPCs.
## Offline path is untouched: every public function no-ops unless isOnline.

signal hosted
signal joined
signal join_failed(reason: String)
signal lobby_updated
signal host_left

const MAX_SLOTS := 4

var isOnline := false
var isHost := false
var localSlot := -1
var port := 7777
var peer: ENetMultiplayerPeer = null
var slotByPeer: Dictionary = {} # peer_id -> slot
var remoteInputs: Dictionary = {} # slot -> [move: Vector2, aim: Vector2]
var upnp: UPNP = null

var _wasJoined := false
var _joinTimer: SceneTreeTimer = null

func _ready() -> void:
	port = int(ProjectSettings.get_setting("papope/online_port", 7777))
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

# ------------------------------------------------------------------ lifecycle

func listRooms() -> Array:
	# Stub for a future lobby registry; v1 is manual IP only.
	return []

func host(gamePort: int = -1) -> bool:
	leave()
	if gamePort > 0:
		port = gamePort
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_SLOTS - 1)
	if err != OK:
		peer = null
		emit_signal("join_failed", "could not host on port %d" % port)
		return false
	multiplayer.multiplayer_peer = peer
	isOnline = true
	isHost = true
	localSlot = 0
	slotByPeer = {1: 0}
	remoteInputs.clear()
	_setup_upnp()
	_reset_lobby_state()
	emit_signal("hosted")
	push_lobby()
	return true

func join(ipText: String) -> void:
	leave()
	var ip := ipText.strip_edges()
	var joinPort := port
	if ip.contains(":"):
		var parts := ip.split(":")
		ip = parts[0].strip_edges()
		if parts.size() > 1 and parts[1].strip_edges().is_valid_int():
			joinPort = int(parts[1].strip_edges())
	if ip.is_empty():
		emit_signal("join_failed", "enter host ip first")
		return
	peer = ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, joinPort)
	if err != OK:
		peer = null
		emit_signal("join_failed", "could not connect to %s" % ipText)
		return
	multiplayer.multiplayer_peer = peer
	isOnline = true
	isHost = false
	localSlot = -1
	_wasJoined = false
	_joinTimer = get_tree().create_timer(10.0)
	_joinTimer.timeout.connect(_on_join_timeout)

func leave() -> void:
	_teardown_upnp()
	if peer != null:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = null
	isOnline = false
	isHost = false
	localSlot = -1
	port = int(ProjectSettings.get_setting("papope/online_port", 7777))
	slotByPeer.clear()
	remoteInputs.clear()
	_wasJoined = false
	# Restore offline connection flags from real hardware.
	var joypads := Input.get_connected_joypads()
	for i in range(MAX_SLOTS):
		Global.playersConnected[i] = joypads.has(i)
		if not Global.playersConnected[i]:
			Global.playersJoined[i] = false

func get_local_ips() -> String:
	var addrs := IP.get_local_addresses()
	var pick := ""
	for a in addrs:
		if a.begins_with("127.") or a.contains(":"):
			continue
		if a.begins_with("192.168.") or a.begins_with("10."):
			return a
		if pick.is_empty():
			pick = a
	return pick if not pick.is_empty() else "127.0.0.1"

# ------------------------------------------------------------------ host helpers

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
	sync_lobby.rpc(
		Global.playersConnected.duplicate(),
		Global.playersJoined.duplicate(),
		Global.playersTeam.duplicate(),
		Global.playersSkin.duplicate(),
		Global.optionsSelected.duplicate(),
		Global.playersPoints.duplicate(),
		slotByPeer.duplicate()
	)

func begin_countdown() -> void:
	if not isOnline or not isHost:
		return
	do_countdown.rpc()

func cancel_countdown() -> void:
	if not isOnline or not isHost:
		return
	undo_countdown.rpc()

func host_start_match() -> void:
	# Called on the host when a round should begin (lobby countdown or banner).
	if not isOnline or not multiplayer.is_server():
		return
	if Global.getWinnerTeamByScore() >= 0:
		# Podium data is final here: pre-derive post-match achievements so the
		# transmitted lists render identically on all screens.
		for i in range(4):
			if Global.playersJoined[i]:
				Global.finalizeAchievements(i)
		enter_postgame.rpc(Global.playersAchievements.duplicate(true), Global.playersStats.duplicate(true), Global.playersKills.duplicate())
		return
	var mapName := "hell"
	var idx: int = Global.optionsSelected["map"]
	if idx == 0:
		idx = randi() % (Global.options["map"].size() - 1) + 1
	mapName = Global.options["map"][idx]
	Global.matchSeed = randi()
	enter_map.rpc(mapName, Global.playersMaxHp.duplicate(), Global.playersPoints.duplicate(), Global.matchSeed)

func to_lobby() -> void:
	if not isOnline or not isHost:
		return
	go_lobby.rpc()

# ------------------------------------------------------------------ signal handlers

func _on_peer_connected(id: int) -> void:
	if not isOnline or not isHost:
		return
	if slotByPeer.has(id):
		# Duplicate (signal + request_slot both fire): just resync.
		push_lobby()
		return
	var slot := -1
	for i in range(MAX_SLOTS):
		if not Global.playersJoined[i]:
			slot = i
			break
	if slot < 0:
		refuse_slot.rpc_id(id)
		return
	slotByPeer[id] = slot
	Global.playersConnected[slot] = true
	Global.playersJoined[slot] = true
	Global.playersCrowned[slot] = false
	push_lobby()
	var lobby := get_node_or_null("/root/Lobby")
	if lobby != null and lobby.has_method("sendBgTo"):
		lobby.sendBgTo(id)

func _on_peer_disconnected(id: int) -> void:
	if not isOnline:
		return
	if not isHost:
		return
	if not slotByPeer.has(id):
		return
	var slot: int = slotByPeer[id]
	slotByPeer.erase(id)
	remoteInputs.erase(slot)
	Global.playersConnected[slot] = false
	Global.playersJoined[slot] = false
	Global.playersCrowned[slot] = false
	Global.emit_signal("player_remove", slot)
	remove_map_player.rpc(slot)
	push_lobby()

func _on_connected_to_server() -> void:
	if not isOnline or isHost:
		return
	request_slot.rpc_id(1)

func _on_connection_failed() -> void:
	if not isOnline or isHost:
		return
	var msg := "connection failed (host unreachable?)"
	leave()
	emit_signal("join_failed", msg)

func _on_server_disconnected() -> void:
	if not isOnline or isHost:
		return
	leave()
	emit_signal("host_left")
	if get_tree().current_scene != null and get_tree().current_scene.name != "OnlineMenu":
		get_tree().change_scene_to_file("res://scenes/OnlineMenu.tscn")

func _on_join_timeout() -> void:
	if isOnline and not isHost and not _wasJoined:
		leave()
		emit_signal("join_failed", "timed out (is udp port open on host?)")

# ------------------------------------------------------------------ UPnP (best effort)

func _setup_upnp() -> void:
	_teardown_upnp()
	upnp = UPNP.new()
	var err := upnp.discover(2000, 2, "InternetGatewayDevice")
	if err != OK or upnp.get_device_count() < 1:
		push_warning("papope online: UPnP discovery failed, clients need manual port forward")
		return
	var dev: UPNPDevice = upnp.get_device(0)
	var mapErr := dev.add_port_mapping(port, port, "Papope", "UDP", 0)
	if mapErr != OK:
		push_warning("papope online: UPnP port mapping failed, clients need manual port forward")

func _teardown_upnp() -> void:
	if upnp != null and upnp.get_device_count() > 0:
		var dev: UPNPDevice = upnp.get_device(0)
		dev.delete_port_mapping(port, "UDP")
	upnp = null

# ------------------------------------------------------------------ RPCs (any_peer + manual server checks)

@rpc("any_peer", "reliable")
func request_slot() -> void:
	if not isOnline or not multiplayer.is_server():
		return
	_on_peer_connected(multiplayer.get_remote_sender_id())

@rpc("any_peer", "reliable")
func refuse_slot() -> void:
	if not isOnline or isHost:
		return
	leave()
	emit_signal("join_failed", "room is full")

@rpc("any_peer", "call_local", "reliable")
func sync_lobby(connected: Array, joined: Array, team: Array, skin: Array, options: Dictionary, points: Array, peerSlots: Dictionary) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	Global.playersConnected = connected
	Global.playersJoined = joined
	Global.playersTeam = team
	Global.playersSkin = skin
	Global.optionsSelected = options
	Global.playersPoints = points
	slotByPeer = peerSlots
	var me := multiplayer.get_unique_id()
	if isHost:
		localSlot = 0
	elif slotByPeer.has(me):
		localSlot = int(slotByPeer[me])
	else:
		localSlot = -1
	emit_signal("lobby_updated")
	if not isHost and localSlot >= 0 and not _wasJoined:
		_wasJoined = true
		emit_signal("joined")

@rpc("any_peer", "reliable")
func request_lobby_change(kind: String, slot: int, value) -> void:
	if not isOnline or not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if sender != 0 and (not slotByPeer.has(sender) or int(slotByPeer[sender]) != slot):
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

@rpc("any_peer", "call_local", "reliable")
func do_countdown() -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	var lobby := get_node_or_null("/root/Lobby")
	if lobby != null and lobby.has_method("startCountdown") and lobby.countdownNode == null:
		lobby.startCountdown()

@rpc("any_peer", "call_local", "reliable")
func undo_countdown() -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	var lobby := get_node_or_null("/root/Lobby")
	if lobby != null and lobby.has_method("stopCountdown") and lobby.countdownNode != null:
		lobby.stopCountdown()

@rpc("any_peer", "call_local", "reliable")
func enter_map(mapName: String, maxHp: Array, points: Array, mapSeed: int = 123) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	Global.playersMaxHp = maxHp
	Global.playersPoints = points
	Global.matchSeed = mapSeed
	Global.goToMapOnline(mapName)

@rpc("any_peer", "call_local", "reliable")
func enter_postgame(achi: Array = [], stats: Array = [], kills: Array = []) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	if achi.size() == 4:
		Global.playersAchievements = achi
	if stats.size() == 4:
		Global.playersStats = stats
	if kills.size() == 4:
		Global.playersKills = kills
	get_tree().change_scene_to_file("res://scenes/PostGame.tscn")

@rpc("any_peer", "call_local", "reliable")
func go_lobby() -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

@rpc("any_peer", "call_local", "reliable")
func remove_map_player(slot: int) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	var player := Global.getPlayer(slot)
	if player != null:
		player.queue_free()
	if Global.MapControllerNode != null and is_instance_valid(Global.MapControllerNode):
		var hud := Global.MapControllerNode.get_node_or_null("HudCanvas/Hud" + str(slot))
		if hud != null:
			hud.queue_free()

@rpc("any_peer", "reliable")
func spawn_pwrup(spawnerIdx: int, typeIdx: int) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	if Global.MapControllerNode != null and is_instance_valid(Global.MapControllerNode) and Global.MapControllerNode.has_method("spawnNetPwrup"):
		Global.MapControllerNode.spawnNetPwrup(spawnerIdx, typeIdx)

@rpc("any_peer", "reliable")
func ghost_event(nodeIdx: int, colorIdx: int = -1) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	if Global.MapControllerNode != null and is_instance_valid(Global.MapControllerNode) and Global.MapControllerNode.has_method("spawnNetGhost"):
		Global.MapControllerNode.spawnNetGhost(nodeIdx, colorIdx)

@rpc("any_peer", "unreliable")
func push_ghost(pos: Vector2) -> void:
	if not isOnline or isHost:
		return
	if multiplayer.get_remote_sender_id() != 1:
		return
	for ghost in get_tree().get_nodes_in_group("ghosts"):
		if is_instance_valid(ghost) and ghost.has_method("push_snapshot"):
			ghost.push_snapshot(pos)
			break

@rpc("any_peer", "reliable")
func ghost_died() -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	for ghost in get_tree().get_nodes_in_group("ghosts"):
		if is_instance_valid(ghost) and ghost.has_method("mirrorDeath"):
			ghost.mirrorDeath()
			break

@rpc("any_peer", "reliable")
func pellet_eaten(pos: Vector2) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	var best = null
	var bestDist := 48.0
	for node in get_tree().get_nodes_in_group("pellets"):
		if node != null and is_instance_valid(node) and not node.is_queued_for_deletion():
			var d: float = (node as Node2D).global_position.distance_to(pos)
			if d < bestDist:
				bestDist = d
				best = node
	if best != null and best.has_method("consume"):
		best.consume()

@rpc("any_peer", "reliable")
func despawn_pwrup(spawnerIdx: int) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	if Global.MapControllerNode != null and is_instance_valid(Global.MapControllerNode) and Global.MapControllerNode.has_method("despawnNetPwrup"):
		Global.MapControllerNode.despawnNetPwrup(spawnerIdx)

@rpc("any_peer", "reliable")
func car_event(laneName: String, carSpeed: float, paint: int) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var lane := scene.get_node_or_null(laneName)
	if lane != null and lane.has_method("spawnNetCar"):
		lane.spawnNetCar(carSpeed, paint)

@rpc("any_peer", "reliable")
func trap_sprung(trapPos: Vector2) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	var best = null
	var bestDist := 200.0
	for node in get_tree().get_nodes_in_group("conveyables"):
		if node != null and is_instance_valid(node) and node.has_method("showSprung"):
			var d: float = (node as Node2D).global_position.distance_to(trapPos)
			if d < bestDist:
				bestDist = d
				best = node
	if best != null:
		best.showSprung()

@rpc("any_peer", "reliable")
func cactus_hit(cactusPos: Vector2) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	var best = null
	var bestDist := 120.0
	for node in get_tree().get_nodes_in_group("cacti"):
		if node != null and is_instance_valid(node):
			var d: float = (node as Node2D).global_position.distance_to(cactusPos)
			if d < bestDist:
				bestDist = d
				best = node
	if best != null:
		best.bounce()
		best.pinch()

@rpc("any_peer", "unreliable")
func damage_number(text: String, pos: Vector2, color: Color, size: int) -> void:
	# Cosmetic: unreliable on purpose (a dropped number beats a network stall).
	if not isOnline or isHost:
		return
	if multiplayer.get_remote_sender_id() != 1:
		return
	Global.spawnFallingLabel(text, pos, color, size)

@rpc("any_peer", "reliable")
func disco_cycle(idx: int, cycleSeed: int) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	for discoFloor in get_tree().get_nodes_in_group("discofloor"):
		if is_instance_valid(discoFloor) and discoFloor.has_method("adoptCycle"):
			discoFloor.adoptCycle(idx, cycleSeed)
			break

@rpc("any_peer", "reliable")
func collision_fx(pos: Vector2, animScale: float, lookPos: Vector2) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	var anim = Res.CollisionAnimObject.instantiate()
	anim.scale = Vector2(animScale, animScale)
	anim.position = pos
	anim.look_at(lookPos)
	Global.addToScene(anim)

@rpc("any_peer", "reliable")
func bg_frame(frame: int, replay: bool) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	var lobby := get_node_or_null("/root/Lobby")
	if lobby == null or not lobby.has_method("applyBgFrame"):
		return
	lobby.applyBgFrame(frame, replay)

@rpc("any_peer", "reliable")
func request_disco() -> void:
	# Late-loading guest missed the current cycle broadcast; unicast it back.
	if not isOnline or not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	for discoFloor in get_tree().get_nodes_in_group("discofloor"):
		if is_instance_valid(discoFloor):
			var cur: Array = discoFloor.get("_current")
			if cur.size() == 2 and int(cur[0]) >= 0:
				disco_cycle.rpc_id(sender, int(cur[0]), int(cur[1]))
			break

@rpc("any_peer", "reliable")
func round_end(aliveTeamId: int, points: Array) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	Global.playersPoints = points
	if Global.MapControllerNode != null and is_instance_valid(Global.MapControllerNode) and Global.MapControllerNode.has_method("showNetRoundEnd"):
		Global.MapControllerNode.showNetRoundEnd(aliveTeamId)

@rpc("any_peer", "reliable")
func notify_action(slot: int, action: String, aimVec: Vector2, moveVec: Vector2) -> void:
	# Host broadcast: every peer executes the action on its copy of the player.
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	_exec_action(slot, action, aimVec, moveVec)

@rpc("any_peer", "reliable")
func request_action(slot: int, action: String, aimVec: Vector2, moveVec: Vector2) -> void:
	# Client -> host: host executes, then rebroadcasts to everyone.
	if not isOnline or not multiplayer.is_server():
		return
	_exec_action(slot, action, aimVec, moveVec)
	notify_action.rpc(slot, action, aimVec, moveVec)

func _exec_action(slot: int, action: String, aimVec: Vector2, moveVec: Vector2) -> void:
	var player := Global.getPlayer(slot)
	if player == null or not player.alive:
		return
	player.aimOverride = aimVec
	player.hasAimOverride = true
	match action:
		"use":
			player.useItem()
		"dash":
			player.dash(moveVec)
	player.hasAimOverride = false

@rpc("any_peer", "reliable")
func notify_fall(slot: int, isLava: bool) -> void:
	# Client copy fell into a pit the host copy did not; host applies it.
	if not isOnline or not multiplayer.is_server():
		return
	var player := Global.getPlayer(slot)
	if player != null and player.alive and not player.isFallingIntoWater:
		player.fallDown(isLava)

@rpc("any_peer", "unreliable")
func send_input(slot: int, moveVec: Vector2, aimVec: Vector2) -> void:
	if not isOnline or not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not slotByPeer.has(sender) or int(slotByPeer[sender]) != slot:
		return
	remoteInputs[slot] = [moveVec, aimVec]
	var player := Global.getPlayer(slot)
	if player != null:
		player.netMove = moveVec
		player.netAim = aimVec
		player.hasNetAim = true

@rpc("any_peer", "unreliable")
func push_state(states: Array) -> void:
	if not isOnline or isHost:
		return
	if multiplayer.get_remote_sender_id() != 1:
		return
	for s in states:
		if not (s is Array) or s.size() < 10:
			continue
		var player := Global.getPlayer(int(s[0]))
		if player != null and player.has_method("apply_net_state"):
			player.apply_net_state(s)

@rpc("any_peer", "reliable")
func submit_perks(slot: int, perks: Array) -> void:
	if not isOnline or not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not slotByPeer.has(sender) or int(slotByPeer[sender]) != slot:
		return
	Global.playersPerks[slot] = perks.duplicate()
	push_perks.rpc(Global.playersPerks.duplicate(true))

@rpc("any_peer", "call_local", "reliable")
func push_perks(perks: Array) -> void:
	if not isOnline:
		return
	if multiplayer.get_remote_sender_id() != 1 and multiplayer.get_remote_sender_id() != 0:
		return
	Global.playersPerks = perks
	var scene := get_tree().current_scene
	if scene == null:
		return
	for i in range(mini(perks.size(), MAX_SLOTS)):
		if i == localSlot:
			continue # own draft stays authoritative locally
		var node := scene.get_node_or_null("MapController/PerkOverlay/PlayerPerks" + str(i))
		if node != null and node.has_method("sync_remote_perks"):
			node.sync_remote_perks(perks[i])
