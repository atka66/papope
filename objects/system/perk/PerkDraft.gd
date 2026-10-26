class_name PerkDraft
extends Node
## Owns one round's card draft: which card each slot got, what has been
## revealed, and which perks each player ended up with.
##
## Views (PerkOverlay / PerkPanel) only listen to the signals below; they never
## decide anything. Net calls into this node instead of poking UI node paths.
## Global.playersPerks stays the read surface for gameplay (Player, Hud) and is
## only ever written here.

signal dealt(slot: int)
signal revealed(slot: int, perk: int)
signal perks_changed(slot: int)
signal swap_pending(slot: int)
signal slot_done(slot: int)

enum Phase { WAITING, DEALT, SWAPPING, DONE }

const MAX_PERKS := 3
const MAX_SLOTS := 4

## Card rolled for each slot (-1 = slot not playing this round).
var cards: Array = [-1, -1, -1, -1]
var phase: Array = [Phase.DONE, Phase.DONE, Phase.DONE, Phase.DONE]
var revealed_flags: Array = [false, false, false, false]
var perks: Array = [[], [], [], []]

var _joined: Array = [false, false, false, false]


func _ready() -> void:
	# A peer leaving mid-draft must not stall the overlay.
	Global.player_remove.connect(_on_player_remove)


## Roll every card up front. `carried` is the perk list players keep across
## rounds (Global.playersPerks); the roll rejects those, exactly as before.
func open(seed: int, joined: Array, carried: Array) -> void:
	_joined = joined.duplicate()
	perks = []
	for slot in range(MAX_SLOTS):
		var own: Array = carried[slot].duplicate() if slot < carried.size() else []
		perks.append(own)
	cards = PerkDeck.roll_all(seed, perks, _joined)
	for slot in range(MAX_SLOTS):
		revealed_flags[slot] = false
		phase[slot] = Phase.WAITING if _joined[slot] else Phase.DONE


## The card for `slot` finished flying in. Safe to call twice.
func deal(slot: int) -> void:
	if not _valid(slot) or phase[slot] != Phase.WAITING:
		return
	phase[slot] = Phase.DEALT
	emit_signal("dealt", slot)


## Local player flipped their card. Returns the perk (for Net) or -1 if the
## flip was not allowed in the current phase.
func reveal_local(slot: int) -> int:
	if not _valid(slot) or phase[slot] != Phase.DEALT:
		return -1
	if revealed_flags[slot]:
		return -1 # a peer's reveal already landed here; do not pick twice
	var perk: int = cards[slot]
	_reveal(slot, perk)
	# Announce the flip before resolving: the pick message follows it, so peers
	# always see the card turn over before they are marked done.
	if Net.isOnline and slot == Net.localSlot:
		Net.push_perk_reveal(slot, perk)
	_resolve(slot, perk)
	return perk


## A peer flipped their card: mirror the flip here. Idempotent, and it also
## works when the reveal beats this machine's deal animation.
func reveal_remote(slot: int, perk: int) -> void:
	if not _valid(slot) or revealed_flags[slot] or phase[slot] == Phase.DONE:
		return
	cards[slot] = perk
	_reveal(slot, perk)


## Confirm the swap: the new card replaces the chosen pip.
func commit_swap(slot: int, index: int) -> void:
	if not _valid(slot) or phase[slot] != Phase.SWAPPING:
		return
	if index < 0 or index >= perks[slot].size():
		return
	perks[slot][index] = cards[slot]
	emit_signal("perks_changed", slot)
	_finish(slot)


## Host-approved picks for a slot owned by a peer.
func apply_remote_pick(slot: int, new_perks: Array) -> void:
	if not _valid(slot):
		return
	perks[slot] = _ints(new_perks)
	emit_signal("perks_changed", slot)
	if phase[slot] == Phase.DONE:
		return # already mirroring the owner's dwell
	# Mirror the owner's dwell instead of closing instantly: closing early
	# would launch this client's round while the last peer is still reading.
	_finish(slot)


func is_revealed(slot: int) -> bool:
	return _valid(slot) and revealed_flags[slot]


func _reveal(slot: int, perk: int) -> void:
	revealed_flags[slot] = true
	emit_signal("revealed", slot, perk)


func _resolve(slot: int, perk: int) -> void:
	if perk == Global.PerkEnum.RESET:
		perks[slot] = []
		emit_signal("perks_changed", slot)
		_finish(slot)
	elif perks[slot].size() < MAX_PERKS:
		perks[slot].append(perk)
		emit_signal("perks_changed", slot)
		_finish(slot)
	else:
		phase[slot] = Phase.SWAPPING
		emit_signal("swap_pending", slot)


func _finish(slot: int) -> void:
	phase[slot] = Phase.DONE
	Global.playersPerks[slot] = perks[slot].duplicate()
	emit_signal("slot_done", slot)
	_send_pick(slot)


func _send_pick(slot: int) -> void:
	if not Net.isOnline or slot != Net.localSlot:
		return
	if Net.isHost:
		Net.broadcast_perks(slot, Global.playersPerks[slot].duplicate())
	else:
		Net.submit_perks(slot, Global.playersPerks[slot].duplicate())


func _on_player_remove(slot: int) -> void:
	if not _valid(slot):
		return
	_joined[slot] = false
	if phase[slot] != Phase.DONE:
		_finish(slot)


func _valid(slot: int) -> bool:
	return slot >= 0 and slot < MAX_SLOTS


func _ints(a) -> Array:
	var out := []
	if a is Array:
		for x in (a as Array):
			out.append(int(x))
	return out
