extends Node2D

@export var player: RigidBody2D
@export var fromRight: bool = false
@export var fromTop: bool = false

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
	hideItems()
	if fromRight:
		$Anim.play("fromright")
	else:
		$Anim.play("fromleft")
	
	maxHp = Global.playersMaxHp[player.playerId]
	delayedHp = maxHp
	setHudColor(Global.TEAM_COLORS[Global.playersTeam[player.playerId]])
	
	# todo perks
	
	if Global.playersPerks[player.playerId].has(Global.PerkEnum.CHICKEN):
		$Container/ShakeContainer/Face.frame = 6
	else:
		$Container/ShakeContainer/Face.frame = Global.playersSkin[player.playerId]

func _process(delta):
	handleHpBar()
	handleShake()
	prevHp = player.hp
	$Container/ShakeContainer/ScoreLabel.text = str(Global.playersPoints[player.playerId])

func setHudColor(color: Color):
	playerColor = color
	$Container/ShakeContainer/FaceBg.color = playerColor
	$Container/ShakeContainer/HpBar.color = playerColor

func handleHpBar() -> void:
	$Container/ShakeContainer/HpBar.scale = Vector2(min(float(player.hp) / maxHp, 1.0), 1)
	$Container/ShakeContainer/HpBarDelay.scale = Vector2(min(float(delayedHp) / maxHp, 1.0), 1)
	$Container/ShakeContainer/HpBar2.scale = Vector2(max(float(player.hp - maxHp) / maxHp, 0.0), 1)
	$Container/ShakeContainer/HpBarDelay2.scale = Vector2(max(float(delayedHp - maxHp) / maxHp, 0.0), 1)
	if delayedHp > player.hp:
		delayedHp -= 1

	if player.shielded:
		$Container/ShakeContainer/HpBar.color = Color.WHITE
	else:
		$Container/ShakeContainer/HpBar.color = playerColor
	
	$Container/ShakeContainer/HpBarFlicker.scale = $Container/ShakeContainer/HpBar.scale
	$Container/ShakeContainer/HpBarFlicker.visible = player.hp < maxHp * 0.2

func handleShake() -> void:
	if player.hp < prevHp:
		hudShakePwr = 7
		Input.start_joy_vibration(player.playerId, 1.0, 1.0, 0.2) # todo not working, fix it
	if hudShakePwr > 0:
		$Container/ShakeContainer.position = Vector2((randi() % (hudShakePwr * 2)) - hudShakePwr, (randi() % (hudShakePwr * 2)) - hudShakePwr)
		hudShakePwr -= 1
	else:
		$Container/ShakeContainer.position = Vector2.ZERO

	if ammoShakePwr > 0:
		$Container/ShakeContainer/Inventory/Container.position = Vector2((randi() % (ammoShakePwr * 2)) - hudShakePwr, (randi() % (ammoShakePwr * 2)) - ammoShakePwr)
		ammoShakePwr -= 1
	else:
		$Container/ShakeContainer/Inventory/Container.position = Vector2.ZERO

func pickup(item: Global.PwrupEnum, ammo: int) -> void:
	hideItems()
	match item:
		Global.PwrupEnum.REVOLVER:
			$Container/ShakeContainer/Inventory/Container/Revolver/Drum1.show()
			if ammo > 6:
				$Container/ShakeContainer/Inventory/Container/Revolver/Drum2.show()
				$Container/ShakeContainer/Inventory/Container/Revolver/Anim.play("fire_both")
			else:
				$Container/ShakeContainer/Inventory/Container/Revolver/Anim.play("fire_1")
	updateAmmo(item, ammo)
	if fromTop:
		$Container/ShakeContainer/Inventory/Anim.play("fromtop")
	else:
		$Container/ShakeContainer/Inventory/Anim.play("frombottom")

func useItem(item: Global.PwrupEnum, ammo: int) -> void:
	match item:
		Global.PwrupEnum.REVOLVER:
			if ammo > 5:
				$Container/ShakeContainer/Inventory/Container/Revolver/Anim.play("fire_2")
			else:
				$Container/ShakeContainer/Inventory/Container/Revolver/Anim.play("fire_1")
		Global.PwrupEnum.DYNAMITE:
			ammoShakePwr = 5
		Global.PwrupEnum.SHIELD:
			ammoShakePwr = 5
		Global.PwrupEnum.TRAP:
			ammoShakePwr = 5
		Global.PwrupEnum.WHIP:
			ammoShakePwr = 5
	updateAmmo(item, ammo)

func updateAmmo(item: Global.PwrupEnum, ammo: int) -> void:
	match item:
		Global.PwrupEnum.REVOLVER:
			for i in range(6):
				var ammoNode: Node = get_node('Container/ShakeContainer/Inventory/Container/Revolver/Drum1/Ammo' + str(i))
				ammoNode.visible = i < ammo
			for i in range(6, 12):
				var ammoNode: Node = get_node('Container/ShakeContainer/Inventory/Container/Revolver/Drum2/Ammo' + str(i - 6))
				ammoNode.visible = i < ammo
		Global.PwrupEnum.DYNAMITE:
			for i in range(2):
				var ammoNode: Node = get_node('Container/ShakeContainer/Inventory/Container/Dynamite/Ammo' + str(i))
				ammoNode.visible = i < ammo
		Global.PwrupEnum.SHIELD:
			for i in range(2):
				var ammoNode: Node = get_node('Container/ShakeContainer/Inventory/Container/Shield/Ammo' + str(i))
				ammoNode.visible = i < ammo
		Global.PwrupEnum.TRAP:
			for i in range(2):
				var ammoNode: Node = get_node('Container/ShakeContainer/Inventory/Container/Trap/Ammo' + str(i))
				ammoNode.visible = i < ammo
		Global.PwrupEnum.WHIP:
			for i in range(10):
				var ammoNode: Node = get_node('Container/ShakeContainer/Inventory/Container/Whip/Ammo' + str(i))
				ammoNode.visible = i < ammo

func hideItems() -> void:
	$Container/ShakeContainer/Inventory/Container/Revolver/Drum1.hide()
	$Container/ShakeContainer/Inventory/Container/Revolver/Drum2.hide()
	$Container/ShakeContainer/Inventory/Container/Dynamite/Ammo0.hide()
	$Container/ShakeContainer/Inventory/Container/Dynamite/Ammo1.hide()
	$Container/ShakeContainer/Inventory/Container/Shield/Ammo0.hide()
	$Container/ShakeContainer/Inventory/Container/Shield/Ammo1.hide()
	$Container/ShakeContainer/Inventory/Container/Trap/Ammo0.hide()
	$Container/ShakeContainer/Inventory/Container/Trap/Ammo1.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo0.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo1.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo2.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo3.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo4.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo5.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo6.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo7.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo8.hide()
	$Container/ShakeContainer/Inventory/Container/Whip/Ammo9.hide()
