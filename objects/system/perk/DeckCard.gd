class_name DeckCard
extends Sprite2D
## The face-down card that flies out of the deck into a player's panel.
## Purely visual, and split into two authored legs: `rise` pulls the card out of
## the deck into its spot in the fan, `deal` throws it from there into the panel.
## Each instance duplicates a leg so the four cards hold different fan spots and
## tilts instead of four hand-tuned copies. The panel listens for `landed`.

signal landed()

## Where the deck sits (overlay space), where each slot's card hovers in the fan,
## and how far that card is tilted there. Index = panel slot.
const DECK_POS := Vector2(680, 896)
const SPREAD := [
	Vector2(-48, -128), Vector2(-16, -144), Vector2(16, -144), Vector2(48, -128),
]
const TILTS := [-0.261799, -0.0872665, 0.0872664, 0.261799]
## Gap between two cards being dealt: the fan empties one card at a time.
const DEAL_STAGGER := 0.2


func _ready() -> void:
	position = DECK_POS
	hide()


## Rise, wait this slot's turn, then fly into `landing`. Every instance runs this
## from the same moment, so all four cards leave the deck together and are then
## dealt one at a time.
func fly(slot: int, landing: Vector2) -> void:
	position = DECK_POS
	show()
	var tilt: float = TILTS[slot]
	await _play("rise", DECK_POS + SPREAD[slot], tilt, tilt)
	# Even the first card waits one beat: the fan should be seen before it empties.
	await get_tree().create_timer((slot + 1) * DEAL_STAGGER).timeout
	$AudioToss.stream = Res.AudioPlayerDash.pick_random()
	$AudioToss.play()
	await _play("deal", landing, tilt, tilt + TAU)
	hide()
	landed.emit()


## Play one authored leg, aimed at this instance's own end point and tilt. The
## leg is copied into a per-instance library so no two cards share state.
func _play(leg: String, to: Vector2, tilt_from: float, tilt_to: float) -> void:
	var anim := $Anim.get_animation(leg).duplicate(true) as Animation
	anim.track_set_key_value(0, anim.track_get_key_count(0) - 1, to)
	anim.track_set_key_value(1, 0, tilt_from)
	anim.track_set_key_value(1, 1, tilt_to)
	var library := AnimationLibrary.new()
	library.add_animation(leg, anim)
	$Anim.add_animation_library(leg, library)
	$Anim.play(leg + "/" + leg)
	await $Anim.animation_finished
