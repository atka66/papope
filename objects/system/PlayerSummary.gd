extends Node2D

@export var playerId: int = 0
var winner = false
var score = 0
var scoreCurr = 0

func _ready():
	if not Global.playersJoined[playerId]:
		queue_free()
	winner = Global.playersTeam[playerId] == Global.getWinnerTeamByScore()
	distributeAchievements()
	
	$Container/TeamBanner.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		$Container/Face.frame = 6
	else:
		$Container/Face.frame = Global.playersSkin[playerId]

func calculateScore() -> void:
	var points = Global.playersPoints[playerId]
	var pointsText = str(points) + " point"
	if points != 1:
		pointsText += "s"
	var pointsLabel = Res.CustomLabelObject.instantiate()
	pointsLabel.position = Vector2(170, 384)
	pointsLabel.text = pointsText
	pointsLabel.fontSize = 4
	pointsLabel.alignment = Control.LayoutPreset.PRESET_CENTER
	pointsLabel.animation = 'float_in'
	pointsLabel.animation_out = 'float_out'
	pointsLabel.aliveTime = 2
	add_child(pointsLabel)

	score += points * 1000

func showAchievements() -> void:
	for i in len(Global.playersAchievements[playerId]):
		showAchievement(376 + (i * 44), Global.playersAchievements[playerId][i])
		await get_tree().create_timer(0.18).timeout

func showAchievement(y: int, achievement: Global.AchiEnum) -> void:
	var nameLabel = Res.CustomLabelObject.instantiate()
	nameLabel.position = Vector2(32, y)
	nameLabel.text = Global.ACHIEVEMENTS[achievement][0]
	nameLabel.fontSize = 2
	#nameLabel.color = Color.black
	#nameLabel.aliveTime = 0
	nameLabel.audio = Res.AudioPlayerDash.pick_random()
	$Container.add_child(nameLabel)
	var descriptionLabel = Res.CustomLabelObject.instantiate()
	descriptionLabel.position = Vector2(44, y + 24)
	descriptionLabel.text = Global.ACHIEVEMENTS[achievement][1]
	descriptionLabel.fontSize = 1
	#descriptionLabel.color = Color.black
	#descriptionLabel.aliveTime = 0
	$Container.add_child(descriptionLabel)
	score += 100


func finalizePoster(finalizingPlayerId: int) -> void:
	if playerId == finalizingPlayerId:
		if winner:
			$Container/Face.material = null
		else:
			modulate = Color(0.7, 0.7, 0.7)
			var deadLabel = Res.CustomLabelObject.instantiate()
			deadLabel.position = Vector2(170, 200)
			deadLabel.fontSize = 7
			deadLabel.fontColor = Color.BROWN
			deadLabel.alignment = Control.LayoutPreset.PRESET_CENTER
			deadLabel.text = 'dead'
			deadLabel.rotation = 0.15
			$Container.add_child(deadLabel)
			
			var anim = Res.SpawnPlayerAnimObject.instantiate()
			anim.position = $Container/Face.global_position
			anim.withFireSound = true
			Global.addToScene(anim)
			$Container/Anim.play("shake")

func distributeAchievements():
	# check underdog/jatszunkmast achievement
	var optionPoints = Global.options['rounds'][Global.optionsSelected['rounds']]
	if optionPoints >= 3 and Global.playersPoints[playerId] <= optionPoints / 4:
		Global.registerAchievement(playerId, Global.AchiEnum.UNDERDOG)
	# check stat achievements
	var playerStats = Global.playersStats[playerId]
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
	if dyn_use > 3 && float(dyn_dmg) / dyn_use > 70:
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
		scoreCurr += ceil((score - scoreCurr) / 3.0)
		if scoreCurr > score:
			scoreCurr = score
		$Container/MoneyLabel.setText(str(scoreCurr))
