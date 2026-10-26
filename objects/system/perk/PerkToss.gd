class_name PerkToss
extends Sprite2D
## A discarded perk, thrown off the bottom of the screen and blown up where it
## lands. One node per disposal: the pip it came from is reused, so the throw
## owns its own copy of the icon and frees itself when it is done. Nothing here
## touches the draft -- this is pure cosmetics.

const FALL_TIME_MIN := 0.5
const FALL_TIME_MAX := 0.9
const FALL_DROP_MIN := 800.0
const FALL_DROP_MAX := 1000.0
const FALL_CREST_SHARE := 0.1   # how far up it rises before falling
const FALL_DRIFT := 50.0        # px either side
const FALL_SPIN := 1000.0       # degrees either way


func _ready() -> void:
	hframes = len(Global.PerkEnum) + 1


## Toss `discarded` away; the node frees itself, so callers fire and forget.
func throw(discarded: int) -> void:
	frame = Global.perk(discarded).frame
	var fall_time := randf_range(FALL_TIME_MIN, FALL_TIME_MAX)
	var drop := randf_range(FALL_DROP_MIN, FALL_DROP_MAX)

	# Rise, then accelerate down under "gravity" -- the shape dispose() had.
	var arc := create_tween()
	arc.tween_property(self, "position:y", -drop * FALL_CREST_SHARE, fall_time * 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	arc.tween_property(self, "position:y", drop * (1.0 - FALL_CREST_SHARE), fall_time * 0.7) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)

	var toss := create_tween().set_parallel(true)
	toss.tween_subtween(arc)
	toss.tween_property(self, "position:x", position.x + randf_range(-FALL_DRIFT, FALL_DRIFT), fall_time)
	toss.tween_property(self, "rotation", deg_to_rad(randf_range(-FALL_SPIN, FALL_SPIN)), fall_time)
	await toss.finished

	_explode()
	queue_free()


func _explode() -> void:
	# Res.ExplosionAnimObject is untyped (load()), so no `:=` here.
	var explosion = Res.ExplosionAnimObject.instantiate()
	# Its own position, so the puff always lands where the perk did.
	explosion.position = global_position
	explosion.harmful = false
	explosion.shakePwr = 20
	get_tree().current_scene.add_child(explosion)
