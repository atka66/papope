extends Node2D

onready var CustomLabel = preload("res://objects/system/CustomLabel.tscn")
onready var Player = preload("res://objects/Player.tscn")
onready var Hud = preload("res://objects/hud/Hud.tscn")
onready var Dim = preload("res://objects/system/Dim.tscn")
onready var Countdown = preload("res://objects/system/Countdown.tscn")
onready var Pwrup = preload("res://objects/pwrup/Pwrup.tscn")
onready var CollisionAnim = preload("res://objects/anim/CollisionAnim.tscn")
onready var DespawnAnim = preload("res://objects/anim/DespawnAnim.tscn")
onready var WhipcrackAnim = preload("res://objects/anim/WhipcrackAnim.tscn")
onready var ExplosionAnim = preload("res://objects/anim/ExplosionAnim.tscn")
onready var RevolverRay = preload("res://objects/pwrup/RevolverRay.tscn")
onready var Dynamite = preload("res://objects/pwrup/Dynamite.tscn")
onready var Trap = preload("res://objects/pwrup/Trap.tscn")
onready var Car = preload("res://objects/obstacle/Car.tscn")
onready var Lobby = get_node('/root/Lobby')

onready var PwrupSprites = {
	'revolver' : preload("res://sprites/pwrup/pwrup_revolver.tres"),
	'dynamite' : preload("res://sprites/pwrup/pwrup_dynamite.tres"),
	'shield' : preload("res://sprites/pwrup/pwrup_shield.tres"),
	'trap' : preload("res://sprites/pwrup/pwrup_trap.tres"),
	'whip' : preload("res://sprites/pwrup/pwrup_whip.tres")
}

const VERSION = '1.3.0'
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
	["STAYING OUT OF BOUNDS FOR", "TOO LONG RESULTS IN DEATH"],
	["SHIELD DOES NOT SAVE YOU", "FROM FALLING OFF SHIPS", "OR STAYING OUT FOR LONG"],
	["DYNAMITES TEND TO BOUNCE", "BACK FROM A LOT OF THINGS"],
	["YOU CAN AVOID REVOLVER", "SHOTS BY HIDING BEHIND", "CERTAIN OBJECTS"],
	["PICKING UP A POWERUP", "REPLACES YOUR CURRENTLY", "EQUIPPED ONE"],
	["YOU CANNOT MOVE IN SPACE", "ONLY DASH"],
	["SAME COLOR MEANS SAME TEAM"]
]
const ACHIEVEMENTS = {
	'ud': ['underdog', 'low overall score'], # has at most the half of the needed score at the end
	'dm': ['demolition man', 'excels in dynamite tossing'],
	'gs': ['gunslinger', 'accurate with the revolver'],
	'im': ['iron man', 'absorbed a lot of damage']
}
const SKIN_COUNT = 6
const TEAM_COLOR_STRINGS = {
	0: "RED",
	1: "BLUE",
	2: "GREEN",
	3: "YELLOW"
}

# constants for configuring purposes
#TODO assign into a config file
const PWRUP_RESPAWN_TIME = 3 #TODO default 6
const ALLOW_PLAYERS_SET_OPTIONS = true #TODO default true

var options = {
	'map': ['random', 'lava', 'western', 'ship', 'space', 'traffic'],
	'rounds': [1, 3, 5, 9],
	'hp': [1, 50, 100, 200]
}
var optionsSelected = {
	'map': 0,
	'rounds': 1,
	'hp': 2
}
var currentOption = options.keys()[0]

var playersConnected = [false, false, false, false]
#var playersJoined = [false, false, false, false]
#var playersSkin = [0, 1, 2, 3]
#var playersTeam = [0, 1, 2, 3]
#var playersPoints = [0, 0, 0, 0]
var playersJoined = [true, true, false, true]
var playersSkin = [0, 1, 2, 3]
var playersTeam = [0, 1, 2, 3]
var playersPoints = [0, 3, 0, 1]

var playersCrowned = [false, false, false, false]
var playersFrozen = false
#var playersAchievements = [[], [], [], []]
var playersAchievements = [['ud', 'gs'], [], [], ['gs', 'im', 'dm']]
var selectedMap = 'none'

func goToMap():
	if getWinnerTeamByScore() < 0:
		var selectedMapIndex;
		if optionsSelected['map'] == 0:
			selectedMapIndex = (randi() % (len(options['map']) - 1) + 1)
		else:
			selectedMapIndex = optionsSelected['map']

		selectedMap = options['map'][selectedMapIndex];
		
		if selectedMap == 'lava': get_tree().change_scene("res://maps/MapLava.tscn")
		if selectedMap == 'western': get_tree().change_scene("res://maps/MapWestern.tscn")
		if selectedMap == 'ship': get_tree().change_scene("res://maps/MapShip.tscn")
		if selectedMap == 'space': get_tree().change_scene("res://maps/MapSpace.tscn")
		if selectedMap == 'traffic': get_tree().change_scene("res://maps/MapTraffic.tscn")
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
	Lobby.leavePlayer(playerId)
	playersConnected[playerId] = false

func getNumberOfTeams():
	var distinctTeams = []
	for i in playersTeam.size():
		if playersJoined[i] && !distinctTeams.has(playersTeam[i]):
			distinctTeams.append(playersTeam[i])
	return distinctTeams.size()

func _ready():
	Input.connect("joy_connection_changed", self, "_joy_connection_changed")
	
	var connectedControllers = Input.get_connected_joypads()
	for i in range(Global.playersConnected.size()):
		if playersConnected[i] && !connectedControllers.has(i):
			disconnectPlayer(i)
		if !playersConnected[i] && connectedControllers.has(i):
			connectPlayer(i)
	
	randomize()

func _joy_connection_changed(id, connected):
	if connected:
		connectPlayer(id)
	if !connected:
		disconnectPlayer(id)

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
