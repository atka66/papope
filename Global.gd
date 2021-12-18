extends Node2D

signal player_remove(id)

const VERSION = '1.3.3 beta'
const TEAM_COLORS = {
	0: Color(0.9, 0.2, 0.2),
	1: Color(0, 0.3, 0.7),
	2: Color(0.5, 0.9, 0.0),
	3: Color(1.0, 0.7, 0),
	4: Color(0.2, 0.2, 0.2)
}
const HINT_STRINGS = [
	["DEATH MAKES YOU DIE"],
	["BE CAREFUL NOT TO", "FALL OFF THE SHIP"],
	["TRAPS STUN FOR 2 SECONDS"],
	["SHIELD LASTS FOR 5 SECONDS"],
	["STAYING OUT OF BOUNDS FOR", "TOO LONG RESULTS IN DEATH"],
	["SHIELD DOES NOT SAVE YOU", "FROM FALLING OFF SHIPS", "OR STAYING OUT FOR LONG"],
	["DYNAMITES TEND TO BOUNCE", "BACK FROM A LOT OF THINGS"],
	["YOU CAN AVOID REVOLVER", "SHOTS BY HIDING BEHIND", "CERTAIN OBJECTS"],
	["PICKING UP A POWERUP", "REPLACES YOUR CURRENTLY", "EQUIPPED ONE"],
	["YOU CANNOT MOVE IN SPACE", "ONLY DASH"],
	["SAME COLOR MEANS SAME TEAM"]
]
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
	GUERRILLA, CARELESS, TRAITOR, NO_REFUNDS, JATSZUNK_MAST, 
	WAKA_WAKA, GHOSTBUSTER, SPOOKED, TRIPLE_KILL, AINT_GON_FIT, CHICKEN_DINNER
}
const ACHIEVEMENTS = {
	AchiEnum.UNDERDOG : ['underdog', 'low overall score'], # has <= 1/4 of the needed score at the end (score limit min 3)
	AchiEnum.DEMOLITION_MAN : ['demo man', 'great dynamite damage'], # dynamite dmg / thrown dynamites > 75
	AchiEnum.GUNSLINGER : ['gunslinger', 'accurate with the revolver'], # revolver accuracy over 75%
	AchiEnum.HUTS_HUTS : ['huts-huts', 'accurate with the whip'], # whip accuracy over 75%
	AchiEnum.DAREDEVIL : ['daredevil', 'won a round with low health'], # win a round with <= 10% of health
	AchiEnum.GUERRILLA : ['guerrilla', 'well placed traps'], # sprung traps (on enemy) / laid traps > 75%
	AchiEnum.CARELESS : ['careless', 'stepped in his own trap'], # sprung his own trap
	AchiEnum.TRAITOR : ['traitor', 'killed his own teammate'], # killed his own teammate with revolver, dynamite or whip
	AchiEnum.NO_REFUNDS : ['no refunds', 'shield on, still died'], # die while having active shield
	AchiEnum.JATSZUNK_MAST : ['jatszunk mast', 'be underdog with bazsi skin'], # be underdog with bazsi skin (0)
	AchiEnum.WAKA_WAKA : ['waka waka', 'ate a lot of pellets'], # ate a lot of pellets
	AchiEnum.GHOSTBUSTER : ['ghostbuster', 'killed a lot of ghosts'], # killed 5 ghosts
	AchiEnum.SPOOKED : ['spooked', 'scared of ghosts'], # killed by a ghost
	AchiEnum.TRIPLE_KILL : ['triple kill', 'killed 3 enemies in a round'], # 3 enemies killed in 1 round
	AchiEnum.AINT_GON_FIT : ['aint gon fit', 'too many achievements!'], # has at least 7 achievements
	AchiEnum.CHICKEN_DINNER : ['chicken dinner', 'i am a chicken']
}
enum PerkEnum {
	AKIMBO, ARMORED, FAST, SPIKY, CUDDLES, REVERSE,
	BACKFIRE, SLOW, NO_LEGS, TIME_BOMB,
	RESET, RIGHT, LONG_ARMS, CHICKEN,
	HEALTHY, UNHEALTHY, REGENERATION, VAMPIRE
}
const PERKS = {
	PerkEnum.AKIMBO: ['akimbo', 'all pickups are doubled', 1],
	PerkEnum.ARMORED: ['armored', 'incoming damage halved', 2], 
	PerkEnum.FAST: ['fast', 'doubled movement speed', 3],
	PerkEnum.SPIKY: ['spiky', 'touching players hurts them', 4],
	PerkEnum.CUDDLES: ['cuddles', 'touching players heals self', 5],
	PerkEnum.REVERSE: ['reverse', 'inverted movement', 6],
	PerkEnum.BACKFIRE: ['backfire', 'inverted aim', 7],
	PerkEnum.SLOW: ['slow', 'halved movement speed', 8],
	PerkEnum.NO_LEGS: ['no legs', 'can only dash', 9],
	PerkEnum.TIME_BOMB: ['time bomb', 'explodes after 1 minute', 10],
	PerkEnum.RESET: ['reset', 'previous cards removed', 11],
	PerkEnum.RIGHT: ['right', 'because i cannot look left', 12],
	PerkEnum.LONG_ARMS: ['long arms', 'longer aim range', 13],
	PerkEnum.CHICKEN: ['chicken', 'you are a chicken', 14],
	PerkEnum.HEALTHY: ['healthy', 'doubled max health', 15],
	PerkEnum.UNHEALTHY: ['unhealthy', 'halved max health', 16],
	PerkEnum.REGENERATION: ['regeneration', 'regenerates health', 17],
	PerkEnum.VAMPIRE: ['vampire', 'dealing damage heals', 18]
}

const DAMAGE_LAVA = 1
const DAMAGE_REVOLVER = 20
const DAMAGE_WHIP = 30
const DAMAGE_SPACERAY = 25
const DAMAGE_CAR = 20
const DAMAGE_TRAP = 35
const DAMAGE_CACTUS = 10
const DAMAGE_SPIKY = 5
const HEAL_CUDDLES = 5
const HEAL_REGENERATION = 2

const SKIN_COUNT = 6
const TEAM_COLOR_STRINGS = {
	0: "RED",
	1: "BLUE",
	2: "GREEN",
	3: "YELLOW"
}

const CONVEYOR_VEL_AREA = 0.68
const CONVEYOR_VEL_RIGID = Vector2(-200.0, 0)

var options = {
	'mode': ['normal', 'one-hit', 'cards'],
	'map': ['random', 'hell', 'western', 'ship', 'space', 'traffic', 'pacman', 'conveyor'],
	'rounds': [1, 3, 5, 9]
}
var optionsSelected = {
	'mode': ProjectSettings.get("papope/default_option_mode"),
	'map': ProjectSettings.get("papope/default_option_map"),
	'rounds': ProjectSettings.get("papope/default_option_rounds")
}
var currentOption = options.keys()[0]

var playersConnected = [false, false, false, false]
#var playersConnected = [true, true, true, true]
var playersJoined = [false, false, false, false]
#var playersJoined = [true, true, true, true]
var playersPoints = [0, 0, 0, 0]
#var playersPoints = [0, 3, 2, 3]
var playersSkin = [0, 1, 2, 3]
var playersTeam = [0, 1, 2, 3]
var playersKills = [0, 0, 0, 0]
var playersMaxHp = [100, 100, 100, 100]

var playersCrowned = [false, false, false, false]
var playersFrozen = false
var playersAchievements = [[], [], [], []]
#var playersAchievements = [[AchiEnum.UNDERDOG, AchiEnum.JATSZUNK_MAST, AchiEnum.NO_REFUNDS, AchiEnum.GUNSLINGER, AchiEnum.DAREDEVIL, AchiEnum.TRIPLE_KILL, AchiEnum.JATSZUNK_MAST], [AchiEnum.TRIPLE_KILL, AchiEnum.TRIPLE_KILL], [], []]
enum StatEnum {REV_USE, REV_HIT, DYN_USE, DYN_DMG, WHP_USE, WHP_HIT, TRP_USE, TRP_HIT, PELLETS, GHOST_KILL}
var playersStats = []
var playersPerks = [[], [], [], []]
#var playersPerks = [[PerkEnum.HEALTHY], [PerkEnum.UNHEALTHY], [], []]

var selectedMap = 'none'

func goToMap():
	if getWinnerTeamByScore() < 0:
		var selectedMapIndex;
		if optionsSelected['map'] == 0:
			selectedMapIndex = (randi() % (len(options['map']) - 1) + 1)
		else:
			selectedMapIndex = optionsSelected['map']

		selectedMap = options['map'][selectedMapIndex];
		
		if selectedMap == 'hell': get_tree().change_scene("res://maps/MapHell.tscn")
		if selectedMap == 'western': get_tree().change_scene("res://maps/MapWestern.tscn")
		if selectedMap == 'ship': get_tree().change_scene("res://maps/MapShip.tscn")
		if selectedMap == 'space': get_tree().change_scene("res://maps/MapSpace.tscn")
		if selectedMap == 'traffic': get_tree().change_scene("res://maps/MapTraffic.tscn")
		if selectedMap == 'pacman': get_tree().change_scene("res://maps/MapPacman.tscn")
		if selectedMap == 'conveyor': get_tree().change_scene("res://maps/MapConveyor.tscn")
	else:
		get_tree().change_scene("res://maps/PostGame.tscn")

func getWinnerTeam():
	var aliveTeams = []
	for player in get_tree().get_nodes_in_group('players'):
		if player.hp > 0 && !aliveTeams.has(playersTeam[player.playerId]):
			aliveTeams.append(playersTeam[player.playerId])
	
	if len(aliveTeams) == 0:
		return -2 # no one is alive, draw (rare)
	elif len(aliveTeams) == 1:
		return aliveTeams[0] # if only one alive, return the ID of the team
	else:
		return -1 # more than one teams are alive

func getWinnerTeamByScore():
	for i in range(4):
		if playersPoints[i] == options['rounds'][optionsSelected['rounds']]:
			return playersTeam[i]
	return -1

func connectPlayer(playerId):
	playersConnected[playerId] = true

func disconnectPlayer(playerId):
	playersConnected[playerId] = false
	leavePlayer(playerId)
	if get_tree().get_current_scene().get_name() != 'Lobby':
		get_tree().change_scene("res://Lobby.tscn")

func joinPlayer(playerId, silent):
	playersJoined[playerId] = true
	var slot = get_node('/root/Lobby/PlayerSlot' + str(playerId))
	var player = Res.Player.instance()
	connect("player_remove", player, "_on_remove")
	player.playerId = playerId
	player.silent = silent
	slot.add_child(player)

func leavePlayer(playerId):
	playersJoined[playerId] = false
	emit_signal("player_remove", playerId)

func getNumberOfTeams():
	var distinctTeams = []
	for i in playersTeam.size():
		if playersJoined[i] && !distinctTeams.has(playersTeam[i]):
			distinctTeams.append(playersTeam[i])
	return distinctTeams.size()

func _ready():
	Input.connect("joy_connection_changed", self, "_joy_connection_changed")
	
	var connectedControllers = Input.get_connected_joypads()
	for i in range(playersConnected.size()):
		if playersConnected[i] && !connectedControllers.has(i):
			disconnectPlayer(i)
		if !playersConnected[i] && connectedControllers.has(i):
			connectPlayer(i)
	
	randomize()

func _joy_connection_changed(id, connected):
	if id < 4:
		if connected:
			connectPlayer(id)
		if !connected:
			disconnectPlayer(id)

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		if (get_tree().get_current_scene().get_name() == 'Lobby'):
			get_tree().quit()
		else:
			get_tree().change_scene("res://Lobby.tscn")

func registerAchievement(playerId, achievement):
	if !(achievement in playersAchievements[playerId]):
		playersAchievements[playerId].append(achievement)

func incrementStat(playerId, stat, i):
	if playersStats:
		playersStats[playerId][stat] += i

func extendVectorTo(vector, length):
	if vector.length() == 0:
		return Vector2.ZERO
	else:
		return vector * (float(length) / vector.length())

func addKill(playerId):
	Global.playersKills[playerId] += 1
	if Global.playersKills[playerId] == 3:
		Global.registerAchievement(playerId, Global.AchiEnum.TRIPLE_KILL)

func getPlayerNode(playerId):
	for player in get_tree().get_nodes_in_group('players'):
		if player.playerId == playerId:
			return player
	return null

func getRandomDeathString(deathType):
	return [
		DEATH_STRINGS[DeathEnum.DEFAULT][randi() % len(DEATH_STRINGS[DeathEnum.DEFAULT])],
		DEATH_STRINGS[deathType][randi() % len(DEATH_STRINGS[deathType])]
	][randi() % 2]

func shakeScreen(shakePwr):
	get_tree().get_nodes_in_group('controllers')[0].screenShakePwr = shakePwr
