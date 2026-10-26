class_name PerkPanel
extends Node2D
## One player's column in the cards draft. Shows that slot's card, its perk
## pips and the swap prompt. All decisions live in PerkDraft; this node only
## renders the draft's state and forwards the owning slot's input.

signal done()

@export var playerId: int = 0

const EMPTY := PerkPip.EMPTY

var _swap_index: int = 0
var _finished: bool = false

@onready var _card: PerkCard = $Card
@onready var _pips: Array = [$Pips/Pip0, $Pips/Pip1, $Pips/Pip2]


func _ready() -> void:
	if not Global.playersJoined[playerId]:
		hide()
		_finished = true
		return
	$TeamBanner.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Face.frame = 6 if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN) \
		else Global.playersSkin[playerId]
	$RevealPrompt.hide()
	$SwapPrompt.hide()

	var draft := _draft()
	if draft != null:
		draft.dealt.connect(_on_dealt)
		draft.revealed.connect(_on_revealed)
		draft.perks_changed.connect(_on_perks_changed)
		draft.swap_pending.connect(_on_swap_pending)
		draft.slot_done.connect(_on_slot_done)
	_sync_pips(false)

	if draft == null:
		return
	if draft.phase[playerId] == PerkDraft.Phase.DONE:
		# This slot's picks arrived before the overlay existed: nothing to draft.
		_finished = true
	elif draft.is_revealed(playerId):
		# A peer's reveal beat the deal on this machine: show their card now.
		_show_revealed(draft.cards[playerId])


func _draft() -> PerkDraft:
	return Global.PerkDraftNode as PerkDraft


## The deck card for this slot finished flying in.
func deal() -> void:
	var draft := _draft()
	if draft == null:
		return
	draft.deal(playerId)
	if draft.is_revealed(playerId):
		_show_revealed(draft.cards[playerId])


## A slot that is not playing (or already finished) never blocks the overlay.
func is_finished() -> bool:
	return _finished


## True once this slot's card is face up (its reveal beat the deal animation).
func is_revealed() -> bool:
	var draft := _draft()
	return draft != null and draft.is_revealed(playerId)


func is_active() -> bool:
	var draft := _draft()
	return draft != null and not _finished and draft.phase[playerId] != PerkDraft.Phase.DONE


## DEBUG only: reveal without input (test3 / F3).
func force_reveal() -> void:
	var draft := _draft()
	if draft == null:
		return
	draft.reveal_local(playerId)


## Routed by PerkOverlay for the slot that owns this input device.
func handle_input(event: InputEvent) -> void:
	var draft := _draft()
	if draft == null or _finished:
		return
	var kb: bool = Global.ownsKeyboardFor(playerId)
	match draft.phase[playerId]:
		PerkDraft.Phase.DEALT:
			var accept: bool = event.is_action_pressed("accept") \
				or (kb and event.is_action_pressed("kb_accept"))
			if accept:
				draft.reveal_local(playerId)
		PerkDraft.Phase.SWAPPING:
			if event.is_action_pressed("nav_right"):
				_select((_swap_index + 1) % 3)
			elif event.is_action_pressed("nav_left"):
				_select((_swap_index + 2) % 3)
			elif event.is_action_pressed("skin_next"):
				draft.commit_swap(playerId, _swap_index)


func _on_dealt(slot: int) -> void:
	if slot != playerId:
		return
	var draft := _draft()
	if draft == null:
		return
	if draft.is_revealed(slot):
		return # a peer's reveal beat the deal; already on screen
	_card.set_perk(draft.cards[slot])
	$RevealPrompt.show()


func _on_revealed(slot: int, perk: int) -> void:
	if slot != playerId:
		return
	_show_revealed(perk)


func _show_revealed(perk: int) -> void:
	$RevealPrompt.hide()
	_card.set_perk(perk)
	_card.reveal()

func _on_perks_changed(slot: int) -> void:
	if slot == playerId:
		# The swap resolved (or a card was added): no pip is the target any more,
		# so drop the highlight before the icon changes and stays at full bright.
		_clear_selection()
		_sync_pips(true)


func _on_swap_pending(slot: int) -> void:
	if slot != playerId:
		return
	$SwapPrompt.show()
	_select(0)


func _on_slot_done(slot: int) -> void:
	if slot != playerId or _finished:
		return
	_finished = true
	$RevealPrompt.hide()
	$SwapPrompt.hide()
	_clear_selection()
	_sync_pips(true)
	if not Global.playersJoined[playerId]:
		done.emit() # peer left mid-draft: no reason to hold the overlay open
		return
	# The dwell is shared by every peer (it is authored in this scene), so all
	# four overlays close together and the round starts in sync.
	$Anim.play("dwell")


func _on_dwell_finished(anim_name: String) -> void:
	if anim_name == "dwell":
		done.emit()

## Once the swap resolves no pip is the target any more: drop the highlight so
## the replaced icon shows at full brightness on every client.
func _clear_selection() -> void:
	for i in range(_pips.size()):
		_pips[i].set_selected(false)


func _select(index: int) -> void:
	_swap_index = index
	var draft := _draft()
	var perk: int = EMPTY
	if draft != null and index < draft.perks[playerId].size():
		perk = draft.perks[playerId][index]
	for i in range(_pips.size()):
		_pips[i].set_selected(i == index)
	if perk == EMPTY:
		$SwapPrompt/SwappedPerkLabel.text = ""
		$SwapPrompt/SwappedPerkDescriptionLabel.text = ""
		return
	var data := Global.perk(perk)
	$SwapPrompt/SwappedPerkLabel.text = data.display_name
	$SwapPrompt/SwappedPerkDescriptionLabel.text = data.description


func _sync_pips(animate: bool) -> void:
	# Read the draft's list, not Global: perks_changed fires before the draft
	# publishes its copy to Global.playersPerks.
	var draft := _draft()
	var owned: Array = draft.perks[playerId] if draft != null else Global.playersPerks[playerId]
	for i in range(_pips.size()):
		_pips[i].set_perk(owned[i] if i < owned.size() else EMPTY, animate)
