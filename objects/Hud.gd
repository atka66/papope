extends Node2D

export var playerId = 0
export(bool) var fromRight = false
var hspeed = 0

func _ready():
	var color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$FaceBg.color = color
	$HpBar.color = color
	
	$FaceSprite.frame = Global.playersSkin[playerId]
	
	yield(get_tree().create_timer(2.5), "timeout")
	hspeed = 15
	
func _process(delta):
	if hspeed > 0:
		position.x += hspeed * (-1 if fromRight else 1)
		hspeed -= 1
