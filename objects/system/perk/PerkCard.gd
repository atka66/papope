extends Node2D

@export var perk: Global.PerkEnum
var revealed = false
var perkData

func _ready():
	perkData = Global.PERKS[perk]
	$CardSprite/PerkSprite.hframes = len(Global.PerkEnum) + 1
	$CardSprite/PerkSprite.frame = perkData[2]
	$CardSprite/PerkSprite.hide()

func reveal():
	revealed = true
	$Anim.play('reveal')
	$AudioFlip.stream = Res.AudioCardFlip[randi() % len(Res.AudioCardFlip)]
	$AudioFlip.play()

func showAll():
	$CardSprite/PerkSprite.show()
	await get_tree().create_timer(0.3).timeout
	var nameLabel = Res.CustomLabelObject.instantiate()
	nameLabel.position = Vector2(0, 128)
	nameLabel.text = perkData[0]
	nameLabel.fontSize = 4
	nameLabel.animation = 'boom_in'
	nameLabel.alignment = Control.LayoutPreset.PRESET_CENTER
	nameLabel.audio = Res.AudioRoundGo
	add_child(nameLabel)
	
	await get_tree().create_timer(0.1).timeout
	var descLabel = Res.CustomLabelObject.instantiate()
	descLabel.position = Vector2(0, 168)
	descLabel.text = perkData[1]
	descLabel.fontSize = 2
	descLabel.animation = 'boom_in'
	descLabel.alignment = Control.LayoutPreset.PRESET_CENTER
	add_child(descLabel)
