extends Node2D

export var playerId = 0
export(bool) var fromRight = false
var hspeed = 0
var playerColor = null

func _ready():
	playerColor = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$FaceBg.color = playerColor
	$HpBar.color = playerColor
	
	$FaceSprite.frame = Global.playersSkin[playerId]
	if Global.playersJoined[playerId]:
		yield(get_tree().create_timer(2.5), "timeout")
		hspeed = 15

func handleHpBar():
	#$HpBar.scale = Vector2()
	pass

func _process(delta):
	if hspeed > 0:
		position.x += hspeed * (-1 if fromRight else 1)
		hspeed -= 1

	handleHpBar()
