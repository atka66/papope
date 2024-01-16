extends Node2D

@export var playerId: int
var isFinished: bool = false

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

func spawnPerkSlot(slot: int, silent: bool):
	var existingPerk = get_node("PerkSlot" + str(slot))
	if existingPerk:
		existingPerk.dispose()
	var perkSlot = Res.PerkSlotObject.instantiate()
	perkSlot.name = "PerkSlot" + str(slot)
	perkSlot.position = Vector2(90 + (slot * 80), 128)
	if Global.playersPerks[playerId].size() > slot:
		perkSlot.frame = Global.PERKS[Global.playersPerks[playerId][slot]][2]
	else:
		perkSlot.frame = 0
	add_child(perkSlot)
	perkSlot.bump()
