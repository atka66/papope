extends Node2D

onready var CustomLabel = preload("res://objects/CustomLabel.tscn")
onready var Player = preload("res://objects/Player.tscn")
onready var Pwrup = preload("res://objects/Pwrup.tscn")
onready var CollisionAnim = preload("res://objects/anim/CollisionAnim.tscn")
onready var DespawnAnim = preload("res://objects/anim/DespawnAnim.tscn")
onready var Lobby = get_node('/root/Lobby')

const VERSION = '1.3.0'
const TEAM_COLORS = {
	0: Color(0.9, 0.2, 0.2),
	1: Color(0, 0.3, 0.7),
	2: Color(0.5, 0.9, 0.0),
	3: Color(1.0, 0.7, 0)
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
#TODO remove
const MOCKED_CTRL_KEYS = {
	0 : {
		'l_up' : KEY_W,
		'l_left' : KEY_A,
		'l_down' : KEY_S,
		'l_right' : KEY_D,
		'x' : KEY_Q,
		'r' : KEY_E
	},
	1 : {
		'l_up' : KEY_T,
		'l_left' : KEY_F,
		'l_down' : KEY_G,
		'l_right' : KEY_H,
		'x' : KEY_R,
		'r' : KEY_Z
	},
	2 : {
		'l_up' : KEY_I,
		'l_left' : KEY_J,
		'l_down' : KEY_K,
		'l_right' : KEY_L,
		'x' : KEY_U,
		'r' : KEY_P
	},
	3 : {
		'l_up' : KEY_I,
		'l_left' : KEY_J,
		'l_down' : KEY_K,
		'l_right' : KEY_L,
		'x' : KEY_U,
		'r' : KEY_P
	}
}
const SKIN_COUNT = 6

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
var playersJoined = [false, false, false, false]
var playersSkin = [0, 1, 2, 3]
var playersTeam = [0, 1, 2, 3]
var playersPoints = [0, 0, 0, 0]
var playersCrowned = [false, false, false, false]

func connectPlayer(playerId):
	playersConnected[playerId] = true

func disconnectPlayer(playerId):
	Lobby.leavePlayer(playerId)
	playersConnected[playerId] = false

func getNumberOfTeams():
	var distinctTeams = []
	for i in playersTeam.size():
		if !distinctTeams.has(playersTeam[i]):
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
