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
	player.hud = self
	hide()
	$Container/Inventory/RevolverDrum1.hide()
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

func handleHpBar():
	$Container/HpBar.scale = Vector2(min(float(player.hp) / maxHp, 1.0), 1)
	$Container/HpBarDelay.scale = Vector2(min(float(delayedHp) / maxHp, 1.0), 1)
	$Container/HpBar2.scale = Vector2(max(float(player.hp - maxHp) / maxHp, 0.0), 1)
	$Container/HpBarDelay2.scale = Vector2(max(float(delayedHp - maxHp) / maxHp, 0.0), 1)
	if delayedHp > player.hp:
		delayedHp -= 1

	if player.shielded:
		$Container/HpBar.color = Color.WHITE
	else:
		$Container/HpBar.color = playerColor
	
	$Container/HpBarFlicker.scale = $Container/HpBar.scale
	$Container/HpBarFlicker.visible = player.hp < maxHp * 0.2

func _process(delta):
	handleHpBar()

func pickup(item: Global.PwrupEnum) -> void:
	$Container/Inventory/RevolverDrum1.hide()
	match item:
		Global.PwrupEnum.REVOLVER:
			# todo akimbo check
			$Container/Inventory/Anim.play("pickup_revolver")

func discard(item: Global.PwrupEnum) -> void:
	match item:
		Global.PwrupEnum.REVOLVER:
			$Container/Inventory/Anim.play("discard_revolver")
