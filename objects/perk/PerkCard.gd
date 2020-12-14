extends Node2D

export(Global.PerkEnum) var perk
var revealed = false

func _ready():
	var perkData = Global.PERKS[perk]
	$Shine.hide()
	$CardSprite/PerkSprite.hframes = len(Global.PerkEnum)
	$CardSprite/PerkSprite.frame = perkData[2]
	$CardSprite/PerkSprite.hide()
	$PerkName.set_text(perkData[0])
	$PerkName.hide()
	$PerkDesc.set_text(perkData[1])
	$PerkDesc.hide()

func reveal():
	revealed = true
	$Anim.play('reveal1')
	$AudioFlip.stream = Res.AudioCardFlip[randi() % len(Res.AudioCardFlip)]
	$AudioFlip.play()

func _on_Anim_animation_finished(anim_name):
	if anim_name == 'reveal1':
			$CardSprite/PerkSprite.show()
			$PerkName.show()
			$PerkDesc.show()
			$CardSprite.frame = 1
			$Anim.play('reveal2')
			$Shine.show()
