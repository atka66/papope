extends Node2D

export(int) var playerId = 0

func _ready():
	if !Global.playersJoined[playerId]:
		queue_free()
	distributeAchievements()
	var winner = Global.playersTeam[playerId] == Global.getWinnerTeamByScore()
	var color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$WinParticles.hide()
	$Background.hide()
	$Background.color = color
	$Team.color = color
	$Face.frame = Global.playersSkin[playerId]
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	var points = Global.playersPoints[playerId]
	var pointsLabel = Res.CustomLabel.instance()
	pointsLabel.position = Vector2(85, 232)
	pointsLabel.text = str(points)
	pointsLabel.fontSize = 4
	pointsLabel.outline = true
	pointsLabel.aliveTime = 0
	pointsLabel.alignment = Label.ALIGN_CENTER
	add_child(pointsLabel)
	var pointsTextLabel = Res.CustomLabel.instance()
	pointsTextLabel.position = Vector2(85, 256)
	if points == 1:
		pointsTextLabel.text = "point"
	else:
		pointsTextLabel.text = "points"
	pointsTextLabel.fontSize = 2
	pointsTextLabel.outline = true
	pointsTextLabel.aliveTime = 0
	pointsTextLabel.alignment = Label.ALIGN_CENTER
	add_child(pointsTextLabel)
	
	yield(get_tree().create_timer(1.0), "timeout")
	
	if winner:
		$Background/BackgroundAnim.play("appear")
		var winnerLabel = Res.CustomLabel.instance()
		winnerLabel.position = Vector2(85, 348)
		winnerLabel.text = 'winner!'
		winnerLabel.fontSize = 3
		winnerLabel.outline = true
		winnerLabel.aliveTime = 0
		winnerLabel.alignment = Label.ALIGN_CENTER
		winnerLabel.audio = Res.AudioWinner
		add_child(winnerLabel)
		$WinParticles.show()
		$Background.show()
	
	yield(get_tree().create_timer(1.5), "timeout")
	
	for i in len(Global.playersAchievements[playerId]):
		showAchievement(200 - (i * 40), Global.playersAchievements[playerId][i])
		yield(get_tree().create_timer(0.2), "timeout")
	
func _input(event):
	if Input.is_action_just_pressed("ui_accept"):
		get_tree().change_scene("res://Lobby.tscn")

func showAchievement(y, achievement):
	var nameLabel = Res.CustomLabel.instance()
	nameLabel.position = Vector2(12, y)
	nameLabel.text = Global.ACHIEVEMENTS[achievement][0]
	nameLabel.fontSize = 2
	nameLabel.outline = true
	nameLabel.aliveTime = 0
	nameLabel.alignment = Label.ALIGN_LEFT
	add_child(nameLabel)
	var descriptionLabel = Res.CustomLabel.instance()
	descriptionLabel.position = Vector2(12, y + 12)
	descriptionLabel.text = Global.ACHIEVEMENTS[achievement][1]
	descriptionLabel.fontSize = 1
	descriptionLabel.outline = false
	descriptionLabel.aliveTime = 0
	descriptionLabel.alignment = Label.ALIGN_LEFT
	add_child(descriptionLabel)

func distributeAchievements():
	# check underdog/jatszunkmast achievement
	var optionPoints = Global.options['rounds'][Global.optionsSelected['rounds']]
	if optionPoints >= 3 && Global.playersPoints[playerId] <= optionPoints / 4:
		var achievement = null
		if Global.playersSkin[playerId] == 0:
			achievement = Global.Achi.JATSZUNK_MAST
		else:
			achievement = Global.Achi.UNDERDOG
		Global.registerAchievement(playerId, achievement)
	# check stat achievements
	var playerStats = Global.playersStats[playerId]
	var dyn_use = playerStats[Global.Stat.DYN_USE]
	var dyn_dmg = playerStats[Global.Stat.DYN_DMG]
	var rev_use = playerStats[Global.Stat.REV_USE]
	var rev_hit = playerStats[Global.Stat.REV_HIT]
	var whp_use = playerStats[Global.Stat.WHP_USE]
	var whp_hit = playerStats[Global.Stat.WHP_HIT]
	var trp_use = playerStats[Global.Stat.TRP_USE]
	var trp_hit = playerStats[Global.Stat.TRP_HIT]
	if dyn_use > 3 && float(dyn_dmg) / dyn_use > 75:
		Global.registerAchievement(playerId, Global.Achi.DEMOLITION_MAN)
	if rev_use > 3 && float(rev_hit) / rev_use > 0.75:
		Global.registerAchievement(playerId, Global.Achi.GUNSLINGER)
	if whp_use > 3 && float(whp_hit) / whp_use > 0.75:
		Global.registerAchievement(playerId, Global.Achi.HUTS_HUTS)
	if trp_use > 3 && float(trp_hit) / trp_use > 0.75:
		Global.registerAchievement(playerId, Global.Achi.GUERRILLA)
