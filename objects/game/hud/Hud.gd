extends Node2D

@export var player: RigidBody2D
@export var fromRight: bool = false

var playerColor: Color
var hudShakePwr: int = 0
var ammoShakePwr: int = 0

var prevAmmo: int = 0
var prevHp: int = 0
var maxHp: int = 1
var delayedHp: int = 1

func _ready():
	hide()
	if fromRight:
		$Anim.play("fromright")
	else:
		$Anim.play("fromleft")
	
	maxHp = Global.playersMaxHp[player.playerId]
	delayedHp = maxHp
	playerColor = Global.TEAM_COLORS[Global.playersTeam[player.playerId]]
	$Container/FaceBg.color = playerColor
	$Container/HpBar.color = playerColor
	
	# todo perks
	
	if Global.playersPerks[player.playerId].has(Global.PerkEnum.CHICKEN):
		$Container/Face.frame = 6
	else:
		$Container/Face.frame = Global.playersSkin[player.playerId]

func _process(delta):
	pass
