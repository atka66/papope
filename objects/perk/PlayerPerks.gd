extends Node2D

signal finished()

export(int) var playerId
var isFinished = false
var donePerking = false
var swapSelected = 0
var swapped = false

func _ready():
	if !Global.playersJoined[playerId]:
		hide()
		isFinished = true
	$Team.color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		$Face.frame = 6
	else:
		$Face.frame = Global.playersSkin[playerId]
	$RevealLabel.hide()
	$SwapLabel.hide()
	$SwappedPerkLabel.hide()
	$SwappedPerkDescriptionLabel.hide()
	$SwapSelectedFlashing.hide()
	
	for i in range(3):
		spawnPerkSlot(i, true)

func spawnPerkSlot(slot, silent):
	var existingNode = get_node("PerkSlot" + str(slot))
	if existingNode:
		existingNode.dispose()
	var perkSlot = Res.PerkSlot.instance()
	perkSlot.name = "PerkSlot" + str(slot)
	perkSlot.position = Vector2(45 + (slot * 40), 64)
	perkSlot.silent = silent
	if Global.playersPerks[playerId].size() > slot:
		perkSlot.frame = Global.PERKS[Global.playersPerks[playerId][slot]][2]
	else:
		perkSlot.frame = 0
	add_child(perkSlot)

func dealt():
	var randomPerk = randi() % len(Global.PerkEnum)
	while Global.playersPerks[playerId].has(randomPerk):
		randomPerk = randi() % len(Global.PerkEnum)
	var perkCard = Res.PerkCard.instance()
	perkCard.position = Vector2(85, 160)
	perkCard.perk = randomPerk
	add_child(perkCard)
	$RevealLabel.show()

func _input(event):
	var cardNode = get_node("PerkCard")
	if event.device == playerId && cardNode && !donePerking:
		if event.is_action_pressed("ui_accept"):
			if !cardNode.revealed:
				$RevealLabel.hide()
				cardNode.reveal()
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
					$SwapLabel.show()
					$SwappedPerkLabel.show()
					$SwappedPerkDescriptionLabel.show()
					$SwapSelectedFlashing.show()
					updateSwapSelected()
		if cardNode.revealed && Global.playersPerks[playerId].size() == 3:
			if event.is_action_pressed("pl_nav_right"):
				swapSelected = (swapSelected + 1) % 3
				updateSwapSelected()
			if event.is_action_pressed("pl_nav_left"):
				swapSelected = (swapSelected + 5) % 3
				updateSwapSelected()
			if event.is_action_pressed("pl_skin_next"):
				Global.playersPerks[playerId][swapSelected] = cardNode.perk
				$SwapLabel.hide()
				$SwappedPerkLabel.hide()
				$SwappedPerkDescriptionLabel.hide()
				$SwapSelectedFlashing.hide()
				spawnPerkSlot(swapSelected, false)
				finishAnimation()

func updateSwapSelected():
	$SwapSelectedFlashing.position = Vector2(45 + (swapSelected * 40), 64)
	$SwappedPerkLabel.set_text(Global.PERKS[Global.playersPerks[playerId][swapSelected]][0])
	$SwappedPerkDescriptionLabel.set_text(Global.PERKS[Global.playersPerks[playerId][swapSelected]][1])

func finishAnimation():
	donePerking = true
	yield(get_tree().create_timer(3), "timeout")
	isFinished = true
