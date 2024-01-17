extends Node2D

@export var playerId: int
var isFinished: bool = false
var donePerking: bool = false
var swapSelected: int = 0

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

func _input(event):
	if event.device == playerId:
		var cardNode = get_node("PerkCard")
		if cardNode && !donePerking:
			if event.is_action_pressed("accept"):
				if !cardNode.revealed:
					cardNode.reveal()
					$RevealHolder.hide()
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

func updateSwapSelected():
	$SwapHolder/SelectedFlashing.position = Vector2(90 + (swapSelected * 80), 128)
	$SwapHolder/SwappedPerkLabel.setText(Global.PERKS[Global.playersPerks[playerId][swapSelected]][0])
	$SwapHolder/SwappedPerkDescriptionLabel.setText(Global.PERKS[Global.playersPerks[playerId][swapSelected]][1])

func finishAnimation():
	donePerking = true
	await get_tree().create_timer(3).timeout
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
	var randomPerk = getRandomPerk()
	while Global.playersPerks[playerId].has(randomPerk):
		randomPerk = getRandomPerk()
	var perkCard = Res.PerkCardObject.instantiate()
	perkCard.position = Vector2(170, 320)
	perkCard.perk = randomPerk
	add_child(perkCard)
	$RevealHolder.show()

func getRandomPerk():
	return randi() % len(Global.PerkEnum)
