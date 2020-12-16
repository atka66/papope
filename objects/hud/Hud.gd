extends Node2D

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
	playerColor = Global.TEAM_COLORS[Global.playersTeam[player.playerId]]
	$Container/FaceBg.color = playerColor
	$Container/HpBar.color = playerColor
	
	var perks = Global.playersPerks[player.playerId]
	for i in range(len(perks)):
		var perk = Res.Perk.instance()
		perk.hframes = len(Global.PerkEnum)
		perk.frame = Global.PERKS[perks[i]][2]
		perk.position = Vector2(1 + (i * 17), 41)
		$Container.add_child(perk)
	
	hspeed = 15
	
	if Global.playersPerks[player.playerId].has(Global.PerkEnum.CHICKEN):
		$Container/FaceSprite.frame = 6
	else:
		$Container/FaceSprite.frame = Global.playersSkin[player.playerId]

func handleShake():
	if player.hp < prevHp:
		hudShakePwr = 7
	if hudShakePwr > 0:
		$Container.position = Vector2((randi() % (hudShakePwr * 2)) - hudShakePwr, (randi() % (hudShakePwr * 2)) - hudShakePwr)
		hudShakePwr -= 1
		Input.start_joy_vibration(player.playerId, 1.0, 1.0, 0.2)
	else:
		$Container.position = Vector2.ZERO

	if ammoShakePwr > 0:
		$Container/AmmoContainer/HudAmmo.position = Vector2((randi() % (ammoShakePwr * 2)) - hudShakePwr, (randi() % (ammoShakePwr * 2)) - ammoShakePwr)
		ammoShakePwr -= 1
	else:
		$Container/AmmoContainer/HudAmmo.position = Vector2.ZERO

func handleHpBar():
	$Container/HpBar.scale = Vector2(float(player.hp) / maxHp, 1)
	$Container/HpBarDelay.scale = Vector2(float(delayedHp) / maxHp, 1)
	if delayedHp > player.hp:
		delayedHp -= 1

	if player.invulnerable:
		$Container/HpBar.color = Color.white
	else:
		$Container/HpBar.color = playerColor
	
	$Container/HpBarFlicker.scale = $Container/HpBar.scale
	$Container/HpBarFlicker.visible = player.hp < maxHp * 0.2

func handlePwrup():
	$Container/HudRevolver0.visible = player.item == 'revolver'
	$Container/HudRevolver1.visible = player.item == 'revolver' && player.ammo > 6
	$Container/AmmoContainer.visible = player.item == 'dynamite' || player.item == 'shield' || player.item == 'trap' || player.item == 'whip'
	match player.item:
		'revolver':
			if player.ammo > 6:
				for i in range(6):
					get_node('Container/HudRevolver0/Drum/Ammo' + str(i)).show()
					get_node('Container/HudRevolver1/Drum/Ammo' + str(i)).visible = (i + 6) < player.ammo
				if player.ammo < prevAmmo:
					$Container/HudRevolver1/DrumRotate.play('rotate')
			else:
				for i in range(6):
					get_node('Container/HudRevolver0/Drum/Ammo' + str(i)).visible = i < player.ammo
				if player.ammo < prevAmmo:
					$Container/HudRevolver0/DrumRotate.play('rotate')
		'dynamite':
			for i in range(10):
				var ammoNode = get_node('Container/AmmoContainer/HudAmmo/Ammo' + str(i))
				ammoNode.frame = 0
				ammoNode.visible = i < player.ammo
			if player.ammo < prevAmmo:
				ammoShakePwr = 5
		'shield':
			for i in range(10):
				var ammoNode = get_node('Container/AmmoContainer/HudAmmo/Ammo' + str(i))
				ammoNode.frame = 1
				ammoNode.visible = i < player.ammo
			if player.ammo < prevAmmo:
				ammoShakePwr = 5
		'trap':
			for i in range(10):
				var ammoNode = get_node('Container/AmmoContainer/HudAmmo/Ammo' + str(i))
				ammoNode.frame = 2
				ammoNode.visible = i < player.ammo
			if player.ammo < prevAmmo:
				ammoShakePwr = 5
		'whip':
			for i in range(10):
				var ammoNode = get_node('Container/AmmoContainer/HudAmmo/Ammo' + str(i))
				ammoNode.frame = 3
				ammoNode.visible = i < player.ammo
			if player.ammo < prevAmmo:
				ammoShakePwr = 5

func _process(delta):
	if hspeed > 0:
		position.x += hspeed * (-1 if fromRight else 1)
		hspeed -= 1
		
	if player:
		handleShake()
		handleHpBar()
		handlePwrup()
		
		if !player.alive:
			$Container/FaceBg.color = Global.TEAM_COLORS[4]


		$Container/ScoreLabel.set_text(str(Global.playersPoints[player.playerId]))
		
		prevHp = player.hp
		prevAmmo = player.ammo
