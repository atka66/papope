class_name PerkPip
extends Control
## One perk pip in a panel. Pure view: the panel tells it which perk to show
## and whether it is the swap target. Pips are never freed and re-added, so
## there is no "occupied" guesswork and no coordinate arithmetic. A perk that
## gets discarded is thrown away by its own PerkToss node, never by this one,
## so the pip stays free to change at any moment.

const EMPTY := -1
## Where the sprite sits inside the pip's 64x64 cell.
const CELL_CENTER := Vector2(32, 32)

var perk: int = EMPTY

var _shown: int = EMPTY
var _has_shown: bool = false

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_sprite.hframes = len(Global.PerkEnum) + 1
	$Highlight.hide()


## Show `new_perk` (EMPTY clears the pip). A pip that already held a different
## perk throws it away first; an unchanged pip does nothing.
func set_perk(new_perk: int, animate: bool = true) -> void:
	if _has_shown and new_perk == _shown:
		return
	var previous := _shown
	_has_shown = true
	_shown = new_perk
	perk = new_perk

	if animate and previous != EMPTY and new_perk != previous:
		_toss(previous)

	_apply()
	if animate and new_perk != EMPTY:
		$Anim.play("bump")


## Flash the pip as the swap target. The Highlight sits above the sprite (the
## icon fills the whole 64x64 cell), so a flash underneath it would be invisible.
func set_selected(selected: bool) -> void:
	$Highlight.visible = selected
	if selected:
		$Anim.play("flash")
	else:
		if $Anim.current_animation == "flash":
			$Anim.stop()
		# The bump played when a perk is replaced shares this AnimationPlayer, so
		# it can interrupt the flash and leave the veil frozen at whatever alpha
		# it had. Reset the color so the icon is never left dimmed.
		$Highlight.color = Color(0, 0, 0, 0)


## Hand the old perk to a throwaway node and show the new one straight away.
## Nothing here waits, so `_sync_pips` can run again at any point.
func _toss(discarded: int) -> void:
	# Untyped on purpose: Res entries are load() results, and this keeps the
	# pip independent of the editor's global class cache for PerkToss.
	var toss = Res.PerkTossObject.instantiate()
	toss.position = CELL_CENTER
	add_child(toss)
	toss.throw(discarded)


func _apply() -> void:
	_sprite.frame = 0 if perk == EMPTY else Global.perk(perk).frame
