extends Node2D

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
