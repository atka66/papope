extends Node2D

signal finished()

export(int) var playerId
var isFinished = false

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
	if event.device == playerId && cardNode && Input.is_action_just_pressed("ui_accept"):
		if !cardNode.revealed:
			$RevealLabel.hide()
			cardNode.reveal()
			if cardNode.perk == Global.PerkEnum.RESET:
				Global.playersPerks[playerId] = []
			elif cardNode.perk != Global.PerkEnum.NOTHING:
				Global.playersPerks[playerId].append(cardNode.perk)
			yield(get_tree().create_timer(3), "timeout")
			isFinished = true
