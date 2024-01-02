extends Node2D

var hintTimer: int = ProjectSettings.get("papope/hint_timer")

const HINT_STRINGS: Array = [
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

func createHintLabel() -> void:
	var randomHint: Array = HINT_STRINGS.pick_random()
	
	for i in randomHint.size():
		var hintLabel = Res.CustomLabelObject.instantiate()
		hintLabel.text = randomHint[i]
		hintLabel.position = Vector2(0, i*16)
		hintLabel.fontSize = 1
		hintLabel.aliveTime = hintTimer
		add_child(hintLabel)

func _ready():
	while true:
		createHintLabel()
		await get_tree().create_timer(hintTimer).timeout


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
