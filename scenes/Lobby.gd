extends Node2D

var countingDown: bool = false

func _ready():
	get_node('/root/Music').play('menu')
	initPlayers()

func initPlayers() -> void:
	Global.playersFrozen = false
	Global.playersPoints = [0, 0, 0, 0]
	Global.playersAchievements = [[], [], [], []]
	Global.playersPerks = [[], [], [], []]
	
	for i in range(4):
		if ProjectSettings.get("papope/disconnect_on_init"):
			Global.playersJoined[i] = false
		else:
			if Global.playersConnected[i] && Global.playersJoined[i]:
				Global.joinPlayer(i, true)
	
	Global.playersStats = []
	for i in range(4):
		Global.playersStats.append(
			{
				Global.StatEnum.REV_USE: 0, Global.StatEnum.REV_HIT: 0,
				Global.StatEnum.DYN_USE: 0, Global.StatEnum.DYN_DMG: 0,
				Global.StatEnum.WHP_USE: 0, Global.StatEnum.WHP_HIT: 0,
				Global.StatEnum.TRP_USE: 0, Global.StatEnum.TRP_HIT: 0,
				Global.StatEnum.PELLETS: 0, Global.StatEnum.GHOST_KILL: 0
			}
		)

func startCountdown() -> void:
	countingDown = true
	var countdown = Res.CountdownObject.instantiate()
	countdown.position = Vector2(340, 112)
	add_child(countdown)

func stopCountdown() -> void:
	countingDown = false
	for countdown in get_tree().get_nodes_in_group("countdown"):
		countdown.queue_free()
