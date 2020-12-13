extends Node2D

var perkInt
var revealed = false

func _ready():
	perkInt = randi() % len(Global.PerkEnum)
	var perkData = Global.PERKS[perkInt]
	print(perkData)
	$Shine.hide()
	$CardSprite/PerkSprite.hframes = len(Global.PerkEnum)
	$CardSprite/PerkSprite.frame = perkData[2]
	$CardSprite/PerkSprite.hide()
	$CardSprite/PerkName.set_text(perkData[0])
	$CardSprite/PerkName.hide()
	$PerkName.set_text(perkData[0])
	$PerkName.hide()
	$PerkDesc.set_text(perkData[1])
	$PerkDesc.hide()

func reveal():
	revealed = true
	$Anim.play('reveal1')
	yield(get_tree().create_timer(2), "timeout")

func _on_Anim_animation_finished(anim_name):
	if anim_name == 'reveal1':
			$CardSprite/PerkSprite.show()
			$CardSprite/PerkName.show()
			$PerkName.show()
			$PerkDesc.show()
			$CardSprite.frame = 1
			$Anim.play('reveal2')
			$Shine.show()
