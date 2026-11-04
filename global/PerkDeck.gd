class_name PerkDeck
extends RefCounted
## Pure perk-draft rules: no nodes, no networking, no Global writes.
## The only place a card is rolled, so the online and offline paths agree.

const SLOT_SALT := 7919


## Card dealt to `slot` for this round. Online every peer passes the same
## synced round seed, so they all derive the same card. Offline passes a
## fresh random seed (matchSeed is a fixed 123 offline, so it must not be used).
static func roll(seed: int, slot: int, owned: Array) -> int:
	var rng := RandomNumberGenerator.new()
	rng.set_seed(seed + slot * SLOT_SALT)
	var perk_count: int = len(Global.PerkEnum)
	var pick: int = rng.randi() % perk_count
	while owned.has(pick) or (pick == Global.PerkEnum.RESET and owned.is_empty()):
		pick = rng.randi() % perk_count
	return pick


## Roll for every slot at once, so cards exist before the deal animation.
static func roll_all(seed: int, owned: Array, joined: Array) -> Array:
	var cards := []
	for slot in range(joined.size()):
		if not joined[slot]:
			cards.append(-1)
			continue
		var carried: Array = owned[slot] if slot < owned.size() else []
		cards.append(roll(seed, slot, carried))
	return cards