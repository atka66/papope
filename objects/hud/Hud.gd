extends Node2D

export var playerId = 0
export(bool) var fromRight = false

var player = null

var hspeed = 0
var playerColor = null

var prevAmmo = 0

func _ready():
	if !Global.playersJoined[playerId]:
		queue_free()

	playerColor = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$FaceBg.color = playerColor
	$HpBar.color = playerColor
	
	$FaceSprite.frame = Global.playersSkin[playerId]
	if Global.playersJoined[playerId]:
		yield(get_tree().create_timer(2.5), "timeout")
		hspeed = 15

func handleHpBar():
	$HpBar.scale = Vector2(float(player.hp) / Global.options['hp'][Global.optionsSelected['hp']], 1)

func handlePwrup():
	$HudRevolver.visible = player.item == 'revolver'
	if player.item == 'revolver':
		for i in range(6):
			get_node('HudRevolver/Drum/Ammo' + str(i)).visible = i < player.ammo
		if player.ammo < prevAmmo:
			$HudRevolver/DrumRotate.play('rotate')

func _process(delta):
	if hspeed > 0:
		position.x += hspeed * (-1 if fromRight else 1)
		hspeed -= 1
		
	if (player):
		handleHpBar()
		handlePwrup()
		
		prevAmmo = player.ammo
