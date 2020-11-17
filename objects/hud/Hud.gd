extends Node2D

export var playerId = 0
export(bool) var fromRight = false

var player = null

var hspeed = 0
var playerColor = null
var hudShakePwr = 0
var ammoShakePwr = 0

var prevAmmo = 0
var prevHp = 0
var maxHp = Global.options['hp'][Global.optionsSelected['hp']]
var delayedHp = maxHp

func _ready():
	if !Global.playersJoined[playerId]:
		queue_free()

	playerColor = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Container/FaceBg.color = playerColor
	$Container/HpBar.color = playerColor
	
	$Container/FaceSprite.frame = Global.playersSkin[playerId]
	if Global.playersJoined[playerId]:
		yield(get_tree().create_timer(2.5), "timeout")
		hspeed = 15

func handleShake():
	if player.hp < prevHp:
		hudShakePwr = 7
	if hudShakePwr > 0:
		$Container.position = Vector2((randi() % (hudShakePwr * 2)) - hudShakePwr, (randi() % (hudShakePwr * 2)) - hudShakePwr)
		hudShakePwr -= 1
		#TODO vibration
	else:
		$Container.position = Vector2.ZERO
		#TODO no vibration

	if ammoShakePwr > 0:
		$Container/AmmoContainer/HudAmmo.position = Vector2((randi() % (ammoShakePwr * 2)) - hudShakePwr, (randi() % (ammoShakePwr * 2)) - ammoShakePwr)
		ammoShakePwr -= 1
	else:
		$Container/AmmoContainer/HudAmmo.position = Vector2.ZERO

func handleHpBar():
	$Container/HpBar.scale = Vector2(float(player.hp) / maxHp, 1)
	if delayedHp > player.hp:
		delayedHp -= 1
	$Container/HpBarDelay.scale = Vector2(float(delayedHp) / maxHp, 1)

func handlePwrup():
	$Container/HudRevolver.visible = player.item == 'revolver'
	$Container/AmmoContainer.visible = player.item == 'dynamite' || player.item == 'shield' || player.item == 'trap' || player.item == 'whip'
	if player.item == 'revolver':
		for i in range(6):
			get_node('Container/HudRevolver/Drum/Ammo' + str(i)).visible = i < player.ammo
		if player.ammo < prevAmmo:
			$Container/HudRevolver/DrumRotate.play('rotate')
	if player.item == 'dynamite':
		for i in range(5):
			var ammoNode = get_node('Container/AmmoContainer/HudAmmo/Ammo' + str(i))
			ammoNode.frame = 0
			ammoNode.visible = i < player.ammo
		if player.ammo < prevAmmo:
			ammoShakePwr = 5
	if player.item == 'shield':
		for i in range(5):
			var ammoNode = get_node('Container/AmmoContainer/HudAmmo/Ammo' + str(i))
			ammoNode.frame = 1
			ammoNode.visible = i < player.ammo
		if player.ammo < prevAmmo:
			ammoShakePwr = 5
	if player.item == 'trap':
		for i in range(5):
			var ammoNode = get_node('Container/AmmoContainer/HudAmmo/Ammo' + str(i))
			ammoNode.frame = 2
			ammoNode.visible = i < player.ammo
		if player.ammo < prevAmmo:
			ammoShakePwr = 5
	if player.item == 'whip':
		for i in range(5):
			var ammoNode = get_node('Container/AmmoContainer/HudAmmo/Ammo' + str(i))
			ammoNode.frame = 3
			ammoNode.visible = i < player.ammo
		if player.ammo < prevAmmo:
			ammoShakePwr = 5

func _process(delta):
	if hspeed > 0:
		position.x += hspeed * (-1 if fromRight else 1)
		hspeed -= 1
		
	if (player):
		handleShake()
		handleHpBar()
		handlePwrup()
		
		$Container/ScoreLabel.set_text(str(Global.playersPoints[playerId]))
		
		prevHp = player.hp
		prevAmmo = player.ammo
