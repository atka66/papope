extends Node2D

export(int) var playerId = 0
var winner = false
var score = 0
var scoreCurr = 0

func _ready():
	if !Global.playersJoined[playerId]:
		queue_free()
	winner = Global.playersTeam[playerId] == Global.getWinnerTeamByScore()
	distributeAchievements()
	var color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Team.color = color
	if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		$Face.frame = 6
	else:
		$Face.frame = Global.playersSkin[playerId]
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	var points = Global.playersPoints[playerId]
	var pointsText = str(points) + " point"
	if points != 1:
		pointsText += "s"
	var pointsLabel = Res.CustomLabel.instance()
	pointsLabel.position = Vector2(85, 192)
	pointsLabel.text = pointsText
	pointsLabel.fontSize = 3
	pointsLabel.aliveTime = 0
	pointsLabel.alignment = Label.ALIGN_CENTER
	pointsLabel.animate = true
	pointsLabel.aliveTime = 2
	add_child(pointsLabel)

	score += points * 1000
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	var fun = showAchievements()
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	if winner:
		$Face.material = null
	else:
		yield(get_tree().create_timer(0.15 * playerId), "timeout")
		modulate = Color(0.7, 0.7, 0.7)
		var winnerLabel = Res.CustomLabel.instance()
		winnerLabel.fontSize = 3
		winnerLabel.outline = true
		winnerLabel.aliveTime = 0
		winnerLabel.alignment = Label.ALIGN_CENTER
		winnerLabel.position = Vector2(85, 92)
		winnerLabel.color = Color.red
		winnerLabel.text = 'dead'
		winnerLabel.animate = false
		add_child(winnerLabel)
		var explosionAnim = Res.ExplosionAnim.instance()
		explosionAnim.position = $Face.global_position
		explosionAnim.harmful = false
		explosionAnim.shakePwr = 0
		get_tree().get_current_scene().add_child(explosionAnim)
		$Anim.play("shake")

func showAchievements():
	for i in len(Global.playersAchievements[playerId]):
		showAchievement(192 + (i * 22), Global.playersAchievements[playerId][i])
		yield(get_tree().create_timer(0.18), "timeout")

func showAchievement(y, achievement):
	var nameLabel = Res.CustomLabel.instance()
	nameLabel.position = Vector2(10, y)
	nameLabel.text = Global.ACHIEVEMENTS[achievement][0]
	nameLabel.fontSize = 2
	nameLabel.outline = false
	nameLabel.color = Color.black
	nameLabel.aliveTime = 0
	nameLabel.alignment = Label.ALIGN_LEFT
	nameLabel.audio = Res.AudioPlayerDash[randi() % len(Res.AudioPlayerDash)]
	add_child(nameLabel)
	var descriptionLabel = Res.CustomLabel.instance()
	descriptionLabel.position = Vector2(14, y + 11)
	descriptionLabel.text = Global.ACHIEVEMENTS[achievement][1]
	descriptionLabel.fontSize = 1
	descriptionLabel.outline = false
	descriptionLabel.color = Color.black
	descriptionLabel.aliveTime = 0
	descriptionLabel.alignment = Label.ALIGN_LEFT
	add_child(descriptionLabel)
	score += 100

func distributeAchievements():
	# check underdog/jatszunkmast achievement
	var optionPoints = Global.options['rounds'][Global.optionsSelected['rounds']]
	if optionPoints >= 3 && Global.playersPoints[playerId] <= optionPoints / 4:
		var achievement = null
		if Global.playersSkin[playerId] == 0:
			achievement = Global.AchiEnum.JATSZUNK_MAST
		else:
			achievement = Global.AchiEnum.UNDERDOG
		Global.registerAchievement(playerId, achievement)
	# check stat achievements
	var playerStats = {
				Global.StatEnum.REV_USE: 0, Global.StatEnum.REV_HIT: 0,
				Global.StatEnum.DYN_USE: 0, Global.StatEnum.DYN_DMG: 0,
				Global.StatEnum.WHP_USE: 0, Global.StatEnum.WHP_HIT: 0,
				Global.StatEnum.TRP_USE: 0, Global.StatEnum.TRP_HIT: 0,
				Global.StatEnum.PELLETS: 0, Global.StatEnum.GHOST_KILL: 0
			}
	var dyn_use = playerStats[Global.StatEnum.DYN_USE]
	var dyn_dmg = playerStats[Global.StatEnum.DYN_DMG]
	var rev_use = playerStats[Global.StatEnum.REV_USE]
	var rev_hit = playerStats[Global.StatEnum.REV_HIT]
	var whp_use = playerStats[Global.StatEnum.WHP_USE]
	var whp_hit = playerStats[Global.StatEnum.WHP_HIT]
	var trp_use = playerStats[Global.StatEnum.TRP_USE]
	var trp_hit = playerStats[Global.StatEnum.TRP_HIT]
	var pellets = playerStats[Global.StatEnum.PELLETS]
	var ghost_kill = playerStats[Global.StatEnum.GHOST_KILL]
	if dyn_use > 3 && float(dyn_dmg) / dyn_use > 75:
		Global.registerAchievement(playerId, Global.AchiEnum.DEMOLITION_MAN)
	if rev_use > 3 && float(rev_hit) / rev_use > 0.75:
		Global.registerAchievement(playerId, Global.AchiEnum.GUNSLINGER)
	if whp_use > 3 && float(whp_hit) / whp_use > 0.75:
		Global.registerAchievement(playerId, Global.AchiEnum.HUTS_HUTS)
	if trp_use > 3 && float(trp_hit) / trp_use > 0.75:
		Global.registerAchievement(playerId, Global.AchiEnum.GUERRILLA)
	if pellets >= 100:
		Global.registerAchievement(playerId, Global.AchiEnum.WAKA_WAKA)
	if ghost_kill >= 5:
		Global.registerAchievement(playerId, Global.AchiEnum.GHOSTBUSTER)

	if winner && Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		Global.registerAchievement(playerId, Global.AchiEnum.CHICKEN_DINNER)

	if len(Global.playersAchievements[playerId]) > 6:
		Global.playersAchievements[playerId].insert(7, Global.AchiEnum.AINT_GON_FIT)

func _process(delta):
	if scoreCurr < score:
		scoreCurr += ceil((score - scoreCurr) / 3)
		if scoreCurr > score:
			scoreCurr = score
		$MoneyLabel.set_text(str(scoreCurr))
