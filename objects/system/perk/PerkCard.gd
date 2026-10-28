class_name PerkCard
extends Node2D
## A single dealt card. Pure view: PerkPanel sets the perk and plays the
## reveal. The flip, the shine and the name/description pop-in are all
## authored in the scene's AnimationPlayer, so nothing here waits on timers.

var perk: int = -1
var revealed: bool = false

@onready var _perk_sprite: Sprite2D = $CardSprite/PerkSprite
@onready var _shine: CPUParticles2D = $Shine
@onready var _name_label: Label = $NameLabel
@onready var _desc_label: Label = $DescLabel


func _ready() -> void:
	_perk_sprite.hframes = len(Global.PerkEnum) + 1
	_reset()
	hide() # stays hidden until this slot's card is dealt


func _reset() -> void:
	revealed = false
	$Anim.stop()
	$CardSprite.frame = 0
	$CardSprite.scale = Vector2(2, 2)
	_perk_sprite.hide()
	_shine.emitting = false
	_name_label.hide()
	_desc_label.hide()


func set_perk(new_perk: int) -> void:
	perk = new_perk
	var data := Global.perk(new_perk)
	_perk_sprite.frame = data.frame
	_name_label.text = data.display_name
	_desc_label.text = data.description
	show()


func reveal() -> void:
	if revealed:
		return
	revealed = true
	$AudioFlip.stream = Res.AudioCardFlip[randi() % len(Res.AudioCardFlip)]
	$AudioFlip.play()
	$Anim.play("reveal")
