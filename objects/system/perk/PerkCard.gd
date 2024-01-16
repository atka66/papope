extends Node2D

@export var perk: Global.PerkEnum
var revealed = false

func _ready():
	var perkData = Global.PERKS[perk]
	$CardSprite/PerkSprite.hframes = len(Global.PerkEnum) + 1
	$CardSprite/PerkSprite.frame = perkData[2]
	$CardSprite/PerkSprite.hide()

func reveal():
	revealed = true
	$Anim.play('reveal')
	$AudioFlip.stream = Res.AudioCardFlip[randi() % len(Res.AudioCardFlip)]
	$AudioFlip.play()
