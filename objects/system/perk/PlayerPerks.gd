extends Node2D

@export var playerId: int
# Shared dwell after a pick: the owner and every remote mirror wait this long
# before isFinished, so all four overlays close together (round start stays in
# sync). A pick is sent at the start of the owner's dwell, so remote timers
# land at (or just after) the owner's.
const FINISH_DELAY := 3.0

var isFinished: bool = false
var donePerking: bool = false
var finishing: bool = false
var swapSelected: int = 0
# A remote reveal can arrive before this slot's card has been dealt; hold the
# perk here and let dealt() reveal it as soon as the card exists.
var pendingRevealPerk: int = -1

# Called when the node enters the scene tree for the first time.
func _ready():
	if !Global.playersJoined[playerId]:
		hide()
		isFinished = true
	$TeamBanner.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		$Face.frame = 6
	else:
		$Face.frame = Global.playersSkin[playerId]
	$RevealHolder.hide()
	$SwapHolder.hide()
	
	for i in range(3):
		spawnPerkSlot(i, true)

func _process(_delta):
	if Net.isOnline and !Global.playersJoined[playerId]:
		# Peer left mid-draft: don't stall the overlay.
		isFinished = true
		hide()

func ownsKeyboard() -> bool:
	# Mirror Player.gd: online the local slot owns both schemes.
	if Net.isOnline:
		return playerId == Net.localSlot
	return Global.playersInputMode[playerId] == Global.InputMode.KB

func _ownsInput(event: InputEvent) -> bool:
	# Keyboard + mouse both report device 0, so match by event kind: only the
	# KB-owning slot takes them, and a pad slot never claims a key/mouse event
	# just because its joypad index happens to be 0 (e.g. KB slot 0 + pad 0 in slot 1).
	if event is InputEventKey or event is InputEventMouse:
		return ownsKeyboard()
	# Online: the local slot owns every scheme (device ids are per-machine).
	if Net.isOnline:
		return playerId == Net.localSlot
	# Pad slots: compare against the bound joypad index, not the slot index.
	var dev := Global.deviceForPlayer(playerId)
	return dev >= 0 and event.device == dev

func _input(event):
	if Global.DEBUG && Input.is_action_just_pressed("test3"):
		var cardNode = get_node("PerkCard")
		if cardNode && !donePerking && !cardNode.revealed:
			_revealLocal(cardNode)
	if _ownsInput(event):
		var cardNode = get_node("PerkCard")
		if cardNode && !donePerking:
			# Pad accept, or kb_accept (Enter) for the slot that owns the keyboard.
			var kbAccept: bool = ownsKeyboard() and event.is_action_pressed("kb_accept")
			if event.is_action_pressed("accept") or kbAccept:
				if !cardNode.revealed:
					_revealLocal(cardNode)
			if cardNode.revealed && Global.playersPerks[playerId].size() == 3:
				if event.is_action_pressed("nav_right"):
					swapSelected = (swapSelected + 1) % 3
					updateSwapSelected()
				if event.is_action_pressed("nav_left"):
					swapSelected = (swapSelected + 5) % 3
					updateSwapSelected()
				if event.is_action_pressed("skin_next"):
					Global.playersPerks[playerId][swapSelected] = cardNode.perk
					$SwapHolder.hide()
					spawnPerkSlot(swapSelected, false)
					finishAnimation()

func _revealLocal(cardNode) -> void:
	# Own-card reveal: flip it, tell the other clients, then resolve the pick.
	cardNode.reveal()
	$RevealHolder.hide()
	if Net.isOnline and playerId == Net.localSlot:
		Net.push_perk_reveal(playerId, cardNode.perk)
	if cardNode.perk == Global.PerkEnum.RESET:
		var perkCount = Global.playersPerks[playerId].size()
		Global.playersPerks[playerId] = []
		for i in range(perkCount):
			spawnPerkSlot(i, false)
		finishAnimation()
	elif Global.playersPerks[playerId].size() < 3:
		Global.playersPerks[playerId].append(cardNode.perk)
		spawnPerkSlot(Global.playersPerks[playerId].size() - 1, false)
		finishAnimation()
	else:
		$SwapHolder.show()
		updateSwapSelected()

func remote_reveal(perk: int) -> void:
	# A peer revealed their card: mirror the flip on this machine. If the card
	# is not dealt yet, remember the perk and let dealt() reveal it.
	var cardNode = get_node_or_null("PerkCard")
	if cardNode == null:
		pendingRevealPerk = perk
		return
	if cardNode.revealed:
		return
	cardNode.setPerk(perk)
	cardNode.reveal()
	$RevealHolder.hide()

func updateSwapSelected():
	$SwapHolder/SelectedFlashing.position = Vector2(90 + (swapSelected * 80), 128)
	$SwapHolder/SwappedPerkLabel.setText(Global.PERKS[Global.playersPerks[playerId][swapSelected]][0])
	$SwapHolder/SwappedPerkDescriptionLabel.setText(Global.PERKS[Global.playersPerks[playerId][swapSelected]][1])

func finishAnimation():
	donePerking = true
	if Net.isOnline and playerId == Net.localSlot:
		if Net.isHost:
			Net.broadcast_perks(playerId, Global.playersPerks[playerId].duplicate())
		else:
			Net.submit_perks(playerId, Global.playersPerks[playerId].duplicate())
	await get_tree().create_timer(FINISH_DELAY).timeout
	isFinished = true

func sync_remote_perks(perks: Array) -> void:
	# Host-approved picks for a slot owned by another peer.
	Global.playersPerks[playerId] = perks.duplicate()
	var cardNode = get_node_or_null("PerkCard")
	if cardNode != null and not cardNode.revealed:
		# No reveal arrived (message dropped): drop the face-down card.
		cardNode.queue_free()
	# A revealed card stays up so its flip + perk name/desc match the owner's screen.
	for i in range(3):
		spawnPerkSlot(i, true)
	donePerking = true
	$RevealHolder.hide()
	$SwapHolder.hide()
	# Mirror the owner's dwell instead of finishing instantly: closing early
	# here would launch this client's round while the last peer is still
	# reading their card (desync).
	if finishing:
		return
	finishing = true
	await get_tree().create_timer(FINISH_DELAY).timeout
	isFinished = true

func spawnPerkSlot(slot: int, silent: bool):
	var existingPerk = get_node("PerkSlot" + str(slot))
	if existingPerk && existingPerk.frame != 0:
		existingPerk.dispose()
	var perkSlot = Res.PerkSlotObject.instantiate()
	perkSlot.name = "PerkSlot" + str(slot)
	perkSlot.position = Vector2(90 + (slot * 80), 128)
	if Global.playersPerks[playerId].size() > slot:
		perkSlot.frame = Global.PERKS[Global.playersPerks[playerId][slot]][2]
	else:
		perkSlot.frame = 0
	add_child(perkSlot)
	if !silent:
		perkSlot.bump()

func dealt():
	if donePerking:
		return # slot already synced from a peer (overlay raced the map load)
	var rng := _deckRng()
	var randomPerk: int = rng.randi() % len(Global.PerkEnum)
	while (Global.playersPerks[playerId].has(randomPerk) || 
			(randomPerk == Global.PerkEnum.RESET && Global.playersPerks[playerId].size() == 0)):
		randomPerk = rng.randi() % len(Global.PerkEnum)
	var perkCard = Res.PerkCardObject.instantiate()
	perkCard.position = Vector2(170, 320)
	if pendingRevealPerk >= 0:
		# A peer's reveal beat the deal on this machine: show their card now.
		perkCard.perk = pendingRevealPerk
	else:
		perkCard.perk = randomPerk
	add_child(perkCard)
	if pendingRevealPerk >= 0:
		pendingRevealPerk = -1
		perkCard.reveal()
		$RevealHolder.hide()
	else:
		$RevealHolder.show()

func _deckRng() -> RandomNumberGenerator:
	# Online: seed from the synced round seed + slot so every peer deals the
	# same card. Offline draws from the global RNG as before (matchSeed is a
	# fixed 123 offline, so it must not be the seed).
	var rng := RandomNumberGenerator.new()
	if Net.isOnline:
		rng.set_seed(Global.matchSeed + playerId * 7919)
	else:
		rng.set_seed(randi())
	return rng
