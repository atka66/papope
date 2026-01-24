extends Node

signal player_remove(id)

var CameraNode: Camera2D
var MapControllerNode: Node2D
var MusicNode: Node

var disableHotkeys: bool = false

const FEEDBACK_URL = "https://atka-commons-api.alwaysdata.net/feedback"

# main debug mode switch (players joined without controllers, debug key to start game, etc)
@onready var DEBUG = OS.is_debug_build()

@onready var VERSION = ProjectSettings.get('application/config/version')

const TEAM_COLORS = {
	0: Color(0.9, 0.2, 0.2),
	1: Color(0, 0.3, 0.7),
	2: Color(0.5, 0.9, 0.0),
	3: Color(1.0, 0.7, 0),
	4: Color(0.2, 0.2, 0.2)
}
enum DeathEnum {
	DEFAULT, EXPLOSION, REVOLVER, WHIP, WATER, LASER, GHOST, TRAP
}
const DEATH_STRINGS = {
	DeathEnum.DEFAULT : ['oof', 'rip', 'dead', 'oops', 'bye'],
	DeathEnum.EXPLOSION : ['boom', 'kaboom'],
	DeathEnum.REVOLVER : ['bang', 'bam'],
	DeathEnum.WHIP : ['huts', 'crack'],
	DeathEnum.WATER : ['splash', 'blub'],
	DeathEnum.LASER : ['zap', 'bzzz'],
	DeathEnum.GHOST : ['aaah', 'spooked'],
	DeathEnum.TRAP : ['snap', 'got em']
}
enum AchiEnum {
	UNDERDOG, DEMOLITION_MAN, GUNSLINGER, HUTS_HUTS, DAREDEVIL,
	GUERRILLA, CARELESS, TRAITOR, NO_REFUNDS, 
	WAKA_WAKA, GHOSTBUSTER, SPOOKED, TRIPLE_KILL, AINT_GON_FIT, CHICKEN_DINNER
}
const ACHIEVEMENTS = {
	AchiEnum.UNDERDOG : ['underdog', 'low overall score'], # has <= 1/4 of the needed score at the end (score limit min 3)
	AchiEnum.DEMOLITION_MAN : ['boomer', 'great dynamite damage'], # dynamite dmg / thrown dynamites > 70
	AchiEnum.GUNSLINGER : ['gunslinger', 'accurate with the revolver'], # revolver accuracy over 75%
	AchiEnum.HUTS_HUTS : ['huts-huts', 'accurate with the whip'], # whip accuracy over 75%
	AchiEnum.DAREDEVIL : ['daredevil', 'won a round with low health'], # win a round with <= 10% of health
	AchiEnum.GUERRILLA : ['guerrilla', 'well placed traps'], # sprung traps (on enemy) / laid traps > 75%
	AchiEnum.CARELESS : ['careless', 'stepped in his own trap'], # sprung his own trap
	AchiEnum.TRAITOR : ['traitor', 'killed his own teammate'], # killed his own teammate with revolver, dynamite or whip
	AchiEnum.NO_REFUNDS : ['no refunds', 'shield on, still died'], # die while having active shield
	AchiEnum.WAKA_WAKA : ['waka waka', 'ate a lot of pellets'], # ate a lot of pellets
	AchiEnum.GHOSTBUSTER : ['ghostbuster', 'killed a lot of ghosts'], # killed 5 ghosts
	AchiEnum.SPOOKED : ['spooked', 'scared of ghosts'], # killed by a ghost
	AchiEnum.TRIPLE_KILL : ['triple kill', 'killed 3 enemies in a round'], # 3 enemies killed in 1 round
	AchiEnum.AINT_GON_FIT : ['ain\'t gon fit', 'too many achievements!'], # has at least 7 achievements
	AchiEnum.CHICKEN_DINNER : ['chicken dinner', 'i am a chicken']
}
enum PerkEnum {
	AKIMBO, ARMORED, FAST, REVERSE, BACKFIRE, SLOW, NO_LEGS, RESET, RIGHT, 
	LONG_ARMS, CHICKEN, HEALTHY, UNHEALTHY, REGEN, VAMPIRE, PREPARED
}

const PERKS : Dictionary = {
	PerkEnum.AKIMBO: ['akimbo', 'pickups are doubled', 1],
	PerkEnum.ARMORED: ['armored', 'incoming damage halved', 2], 
	PerkEnum.FAST: ['fast', 'doubled movement speed', 3],
	PerkEnum.REVERSE: ['reverse', 'inverted movement', 4],
	PerkEnum.BACKFIRE: ['backfire', 'inverted aim', 5],
	PerkEnum.SLOW: ['slow', 'halved movement speed', 6],
	PerkEnum.NO_LEGS: ['no legs', 'can only dash', 7],
	PerkEnum.RESET: ['reset', 'current cards removed', 8],
	PerkEnum.RIGHT: ['right', 'cannot aim to the left', 9],
	PerkEnum.LONG_ARMS: ['long arms', 'longer aim range', 10],
	PerkEnum.CHICKEN: ['chicken', 'you are a chicken', 11],
	PerkEnum.HEALTHY: ['healthy', 'doubled max health', 12],
	PerkEnum.UNHEALTHY: ['unhealthy', 'halved max health', 13],
	PerkEnum.REGEN: ['regen', 'heals over time', 14],
	PerkEnum.VAMPIRE: ['vampire', 'dealing damage heals', 15],
	PerkEnum.PREPARED: ['prepared', 'starts with random item', 16]
}

enum PwrupEnum { REVOLVER, DYNAMITE, SHIELD, TRAP, WHIP }

const DAMAGE_LAVA = 1
const DAMAGE_REVOLVER = 20
const DAMAGE_WHIP = 30
const DAMAGE_SPACERAY = 25
const DAMAGE_CAR = 20
const DAMAGE_TRAP = 35
const DAMAGE_CACTUS = 10
const HEAL_REGEN = 2

const SKIN_COUNT = 6
const TEAM_COLOR_STRINGS = {
	0: "RED",
	1: "BLUE",
	2: "GREEN",
	3: "YELLOW"
}

const CONVEYOR_VEL_AREA = 1.3
const CONVEYOR_VEL_RIGID = Vector2(-480.0, 0)

var options = {
	'mode': ['normal', 'one-hit', 'cards'],
	'map': ['random', 'hell', 'western', 'ship', 'space', 'highway', 'pacman', 'industrial', 'nightclub'],
	'rounds': [1, 3, 5, 9]
}
var optionInfo = {
	'normal': ['regular rumble', 'the classic papope experience'],
	'one-hit': ['taking any damage', 'kills you instantly'],
	'cards': ['each round begins with', 'modifiers assigned to each player']
}
var optionsSelected = {
	'mode': ProjectSettings.get("papope/default_option_mode"),
	'map': ProjectSettings.get("papope/default_option_map"),
	'rounds': ProjectSettings.get("papope/default_option_rounds")
}

var playersConnected = [false, false, false, false]
var playersJoined = [false, false, false, false]
var playersPoints = [0, 0, 0, 0]
var playersSkin = [0, 1, 2, 3]
var playersTeam = [0, 1, 2, 3]
var playersKills = [0, 0, 0, 0]
var playersMaxHp = [100, 100, 100, 100]

var playersCrowned = [false, false, false, false]
var playersFrozen = false
var playersAchievements = [[], [], [], []]
enum StatEnum {REV_USE, REV_HIT, DYN_USE, DYN_DMG, WHP_USE, WHP_HIT, TRP_USE, TRP_HIT, PELLETS, GHOST_KILL}
var playersStats = []
var playersPerks = [[], [], [], []]
#var playersPerks = [[PerkEnum.HEALTHY], [PerkEnum.UNHEALTHY], [], []]

var selectedMap = 'none'

func _ready():
	randomize()
	
	Input.connect("joy_connection_changed", _joy_connection_changed)
	var connectedControllers = Input.get_connected_joypads()
	for i in range(playersConnected.size()):
		if playersConnected[i] && !connectedControllers.has(i):
			if !DEBUG:
				disconnectPlayer(i)
		if !playersConnected[i] && connectedControllers.has(i):
			connectPlayer(i)
	
	if DEBUG && false: # for testing postgame easily
		playersConnected = [true, true, true, true]
		playersJoined = [true, true, true, true]
		playersPoints = [0, 3, 2, 1]
		playersAchievements = [[AchiEnum.UNDERDOG, AchiEnum.UNDERDOG, AchiEnum.NO_REFUNDS, AchiEnum.GUNSLINGER,AchiEnum.UNDERDOG, AchiEnum.NO_REFUNDS, AchiEnum.GUNSLINGER, AchiEnum.DAREDEVIL], [AchiEnum.TRIPLE_KILL, AchiEnum.TRIPLE_KILL], [], [AchiEnum.NO_REFUNDS, AchiEnum.GUNSLINGER,AchiEnum.UNDERDOG]]
		playersPerks = [[PerkEnum.HEALTHY], [PerkEnum.UNHEALTHY], [], []]
		Global.initPlayerStats()

func _joy_connection_changed(id: int, connected: bool) -> void:
	if id < 4:
		if connected:
			connectPlayer(id)
		else:
			disconnectPlayer(id)

func _input(_event):
	if !disableHotkeys:
		if Input.is_action_just_pressed("fullscreen"):
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if Input.is_action_just_pressed("mute"):
			var bus = AudioServer.get_bus_index("Master")
			var mute = AudioServer.is_bus_mute(bus)
			AudioServer.set_bus_mute(bus, !mute)

func connectPlayer(id: int) -> void:
	playersConnected[id] = true

func disconnectPlayer(id: int) -> void:
	playersConnected[id] = false
	leavePlayer(id)
	if get_tree().get_current_scene().get_name() != 'Lobby':
		goToLobby()

func joinPlayer(id: int, silent: bool) -> void:
	playersJoined[id] = true
	var slot = get_node('/root/Lobby/PlayerSlot' + str(id))
	var player = Res.PlayerObject.instantiate()
	connect("player_remove", player._on_remove)
	player.playerId = id
	player.silent = silent
	slot.add_child(player)

func leavePlayer(id: int) -> void:
	playersJoined[id] = false
	emit_signal("player_remove", id)

func initPlayerStats() -> void:
	Global.playersStats = []
	for i in range(4):
		Global.playersStats.append(
			{
				Global.StatEnum.REV_USE: 0, Global.StatEnum.REV_HIT: 0,
				Global.StatEnum.DYN_USE: 0, Global.StatEnum.DYN_DMG: 0,
				Global.StatEnum.WHP_USE: 0, Global.StatEnum.WHP_HIT: 0,
				Global.StatEnum.TRP_USE: 0, Global.StatEnum.TRP_HIT: 0,
				Global.StatEnum.PELLETS: 0, Global.StatEnum.GHOST_KILL: 0
			}
		)

func goToLobby() -> void:
	get_tree().change_scene_to_file("res://scenes/Lobby.tscn")

func goToMap() -> void:
	if getWinnerTeamByScore() < 0:
		var selectedMapIndex: int
		if optionsSelected['map'] == 0:
			selectedMapIndex = (randi() % (len(options['map']) - 1) + 1)
		else:
			selectedMapIndex = optionsSelected['map']

		selectedMap = options['map'][selectedMapIndex]
		
		if selectedMap == 'hell': get_tree().change_scene_to_file("res://scenes/maps/MapHell.tscn")
		if selectedMap == 'western': get_tree().change_scene_to_file("res://scenes/maps/MapWestern.tscn")
		if selectedMap == 'ship': get_tree().change_scene_to_file("res://scenes/maps/MapShip.tscn")
		if selectedMap == 'space': get_tree().change_scene_to_file("res://scenes/maps/MapSpace.tscn")
		if selectedMap == 'highway': get_tree().change_scene_to_file("res://scenes/maps/MapHighway.tscn")
		if selectedMap == 'pacman': get_tree().change_scene_to_file("res://scenes/maps/MapPacman.tscn")
		if selectedMap == 'industrial': get_tree().change_scene_to_file("res://scenes/maps/MapIndustrial.tscn")
		if selectedMap == 'nightclub': get_tree().change_scene_to_file("res://scenes/maps/MapNightclub.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/PostGame.tscn")

func startRound() -> void:
	playersFrozen = false
	MapControllerNode.playGoSound()
	if selectedMap == 'pacman':
		initGhostSpawn()

func initGhostSpawn():
	MapControllerNode.initGhostSpawn()

func getPlayer(playerId: int) -> Object:
	for player in get_tree().get_nodes_in_group('players'):
		if player.playerId == playerId:
			return player
	return null

func getWinnerTeam() -> int:
	var aliveTeams: Array[int] = []
	for player in get_tree().get_nodes_in_group('players'):
		if player.hp > 0 && !aliveTeams.has(playersTeam[player.playerId]):
			aliveTeams.append(playersTeam[player.playerId])
	
	if len(aliveTeams) == 0:
		return -2
	elif len(aliveTeams) == 1:
		return aliveTeams[0]
	else:
		return -1

func getWinnerTeamByScore() -> int:
	for i in range(4):
		if playersPoints[i] == options['rounds'][optionsSelected['rounds']]:
			return playersTeam[i]
	return -1

func getNumberOfTeams():
	var distinctTeams = []
	for i in playersTeam.size():
		if playersJoined[i] && !distinctTeams.has(playersTeam[i]):
			distinctTeams.append(playersTeam[i])
	return distinctTeams.size()

func registerAchievement(playerId: int, achievement: AchiEnum):
	if not (achievement in playersAchievements[playerId]):
		playersAchievements[playerId].append(achievement)

func incrementStat(playerId : int, stat : StatEnum, i) -> void:
	if playersStats:
		playersStats[playerId][stat] += i

func shakeScreen(shakePwr):
	if shakePwr > 0:
		CameraNode.shakePwr = shakePwr

func extendVectorTo(vector: Vector2, length: float) -> Vector2:
	if vector.length() == 0:
		return Vector2.RIGHT
	return vector * (float(length) / vector.length())

func addToScene(object: Object) -> void:
	get_tree().get_current_scene().add_child(object)

func pacmanWrap(state: PhysicsDirectBodyState2D) -> void:
	if selectedMap == 'pacman':
		var xform = state.transform
		xform.origin.x = wrapf(xform.origin.x, -96, 1456)
		state.transform = xform

func spawnFallingLabel(text: String, position: Vector2, color: Color, size: int) -> void:
	var label = Res.FallingLabelObject.instantiate()
	label.text = text
	label.color = color
	label.size = size
	label.position = position
	addToScene(label)

func getDeathMessage(reason : DeathEnum):
	return [DEATH_STRINGS[reason], DEATH_STRINGS[DeathEnum.DEFAULT]].pick_random().pick_random()

func getRandomPwrup() -> PwrupEnum:
	return [PwrupEnum.REVOLVER, PwrupEnum.DYNAMITE, PwrupEnum.SHIELD, PwrupEnum.TRAP, PwrupEnum.WHIP].pick_random()

func addKill(playerId) -> void:
	playersKills[playerId] += 1
	if playersKills[playerId] == 3:
		registerAchievement(playerId, Global.AchiEnum.TRIPLE_KILL)
