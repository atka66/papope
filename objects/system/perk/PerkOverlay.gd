class_name PerkOverlay
extends Node2D
## Conductor for the cards draft. Opens the draft, fades in, rises the deck into
## a fan and deals one card into each panel, then closes when every panel reports
## done. No decisions and no per-frame polling live here.

signal finished()

## Pause before the deck starts dealing (the map is still settling in).
const DEAL_INTRO_DELAY := 1.5

var _draft: PerkDraft
var _done_count: int = 0
var _closing: bool = false

@onready var _panels: Array = [$Panel0, $Panel1, $Panel2, $Panel3]


func _enter_tree() -> void:
	# Runs before the panels' _ready, so they can read the draft's phases and
	# connect to its signals while they initialise.
	_draft = get_node("PerkDraft")
	Global.PerkDraftNode = _draft
	# Online every peer rolls from the synced round seed, so all four machines
	# deal the same cards. Offline matchSeed is a fixed 123, so roll fresh.
	var round_seed: int = Global.matchSeed if Net.isOnline else randi()
	_draft.open(round_seed, Global.playersJoined, Global.playersPerks)
	# Net may have cached a reveal/pick while this map was still loading.
	var pending: Array = Net.take_pending_draft()
	for slot in pending[0].keys():
		_draft.reveal_remote(int(slot), int(pending[0][slot]))
	for slot in pending[1].keys():
		_draft.apply_remote_pick(int(slot), pending[1][slot])


func _ready() -> void:
	modulate.a = 0.0
	for i in range(_panels.size()):
		_panels[i].done.connect(_on_panel_done)
		if _panels[i].is_finished():
			_done_count += 1
	if _done_count >= _panels.size():
		_close(false) # nothing to show (no draftable slot): skip the fade
		return

	await get_tree().create_timer(DEAL_INTRO_DELAY).timeout
	$Anim.play("appear")
	await $Anim.animation_finished
	# The deck is on screen: its sound plays as every waiting card rises into the
	# fan together. The cards then deal themselves one at a time, each with its
	# own dash, so the fan empties instead of moving as one block.
	$AudioDeckAppear.play()
	for i in range(_panels.size()):
		if _panels[i].is_finished() or _panels[i].is_revealed():
			continue # nothing to deal (or the card is already face up)
		var deck_card: DeckCard = Res.DeckCardObject.instantiate()
		add_child(deck_card)
		deck_card.landed.connect(_panels[i].deal)
		var landing: Vector2 = _panels[i].position + _panels[i].get_node("Card").position
		deck_card.fly(i, landing)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return # only buttons/keys/pad presses can act here
	if Global.DEBUG and Input.is_action_just_pressed("test3"):
		for i in range(_panels.size()):
			if _panels[i].is_active():
				_panels[i].force_reveal()
		return
	var slot := Global.slotOwningEvent(event)
	if slot >= 0:
		_panels[slot].handle_input(event)


func _on_panel_done() -> void:
	_done_count += 1
	if _done_count < _panels.size() or _closing:
		return
	_close()


func _close(animate: bool = true) -> void:
	if _closing:
		return
	_closing = true
	if animate:
		$Anim.play("disappear")
		await $Anim.animation_finished
	finished.emit()
	queue_free()


func _exit_tree() -> void:
	if Global.PerkDraftNode == _draft:
		Global.PerkDraftNode = null
