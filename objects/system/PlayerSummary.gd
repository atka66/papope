extends Node2D

export(int) var playerId = 0

func _ready():
	if !Global.playersJoined[playerId]:
		queue_free()
	var winner = Global.playersTeam[playerId] == Global.getWinnerTeamByScore()
	var color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$WinParticles.hide()
	$Background.hide()
	$Background.color = color
	$Team.color = color
	$Face.frame = Global.playersSkin[playerId]
	
	yield(get_tree().create_timer(2.0), "timeout")
	
	var points = Global.playersPoints[playerId]
	var pointsLabel = Global.CustomLabel.instance()
	pointsLabel.position = Vector2(85, 232)
	pointsLabel.text = str(points)
	pointsLabel.fontSize = 4
	pointsLabel.outline = true
	pointsLabel.aliveTime = 0
	pointsLabel.alignment = Label.ALIGN_CENTER
	add_child(pointsLabel)
	var pointsTextLabel = Global.CustomLabel.instance()
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
		var winnerLabel = Global.CustomLabel.instance()
		winnerLabel.position = Vector2(85, 348)
		winnerLabel.text = 'winner!'
		winnerLabel.fontSize = 3
		winnerLabel.outline = true
		winnerLabel.aliveTime = 0
		winnerLabel.alignment = Label.ALIGN_CENTER
		add_child(winnerLabel)
		$WinParticles.show()
		$Background.show()
	
	yield(get_tree().create_timer(1.0), "timeout")
	
	for i in len(Global.playersAchievements[playerId]):
		showAchievement(200 - (i * 40), Global.playersAchievements[playerId][i])
		yield(get_tree().create_timer(0.25), "timeout")
	
func showAchievement(y, achievement):
	var nameLabel = Global.CustomLabel.instance()
	nameLabel.position = Vector2(12, y)
	nameLabel.text = Global.ACHIEVEMENTS[achievement][0]
	nameLabel.fontSize = 2
	nameLabel.outline = true
	nameLabel.aliveTime = 0
	nameLabel.alignment = Label.ALIGN_LEFT
	add_child(nameLabel)
	var descriptionLabel = Global.CustomLabel.instance()
	descriptionLabel.position = Vector2(12, y + 12)
	descriptionLabel.text = Global.ACHIEVEMENTS[achievement][1]
	descriptionLabel.fontSize = 1
	descriptionLabel.outline = false
	descriptionLabel.aliveTime = 0
	descriptionLabel.alignment = Label.ALIGN_LEFT
	add_child(descriptionLabel)
