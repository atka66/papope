extends Node2D

var perk
var revealed = false

func _ready():
	perk = Global.PERKS[randi() % len(Global.PERKS)]
	$Shine.hide()
	$CardSprite/PerkSprite.hide()
	$CardSprite/PerkName.set_text(perk[0])
	$CardSprite/PerkName.hide()
	$PerkName.set_text(perk[0])
	$PerkName.hide()
	$PerkDesc.set_text(perk[1])
	$PerkDesc.hide()

func reveal():
	revealed = true
	$Shine.show()
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
