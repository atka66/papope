extends Node2D

onready var CustomLabel = preload("res://objects/CustomLabel.tscn")
onready var Player = preload("res://objects/Player.tscn")

const VERSION = '1.3.0'
const PLAYER_COLORS = {
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

var playersConnected = [false, false, false, false]
var playersJoined = [false, false, false, false]
var playersSkin = [0, 1, 2, 3]
var playersTeam = [0, 1, 2, 3]
var playersPoints = [0, 0, 0, 0]
var playersCrowned = [false, false, false, false]

func getNumberOfTeams():
	var distinctTeams = []
	for i in playersTeam.size():
		if !distinctTeams.has(playersTeam[i]):
			distinctTeams.append(playersTeam[i])
	return distinctTeams.size()

func _ready():
	randomize()

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
