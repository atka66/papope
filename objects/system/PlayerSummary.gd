extends Node2D

export(int) var playerId = 0

func _ready():
	if !Global.playersJoined[playerId]:
		queue_free()
	var winner = Global.playersTeam[playerId] == Global.getWinnerTeamByScore()
	var color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Background.color = color
	$Team.color = color
	$Face.frame = Global.playersSkin[playerId]
	var points = Global.playersPoints[playerId]
	$PointsLabel.set_text(str(points))
	if points == 1:
		$PointsTextLabel.set_text("point")
	else:
		$PointsTextLabel.set_text("points")
	if !winner:
		$WinParticles.hide()
		$Background.hide()
		$WinnerLabel.hide()
	
	var achievementCnt = len(Global.playersAchievements[playerId])
	if achievementCnt > 0:
		$Achievement1.setAchievent(Global.ACHIEVEMENTS[Global.playersAchievements[playerId][0]])
	if achievementCnt > 1:
		$Achievement2.setAchievent(Global.ACHIEVEMENTS[Global.playersAchievements[playerId][1]])
	if achievementCnt > 2:
		$Achievement3.setAchievent(Global.ACHIEVEMENTS[Global.playersAchievements[playerId][2]])
	if achievementCnt > 3:
		$Achievement4.setAchievent(Global.ACHIEVEMENTS[Global.playersAchievements[playerId][3]])
