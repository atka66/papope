extends Node2D

const MAX_ACHIEVEMENTS = 8

@export var playerId: int = 0
var winner = false
var score: int = 0
var scoreCurr: int = 0

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

# tween to animate score "count-up"
func tweenScore(countupScore) -> void:
	$Container/KachingAnim.seek(0)
	$Container/KachingAnim.play("kaching")
	var tween = create_tween()
	tween.tween_property(self, "scoreCurr", countupScore, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

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
	pointsLabel.aliveTime = 1.5
	add_child(pointsLabel)

	score += points * 1000
	tweenScore(score)

func showAchievements() -> void:
	for i in min(len(Global.playersAchievements[playerId]), MAX_ACHIEVEMENTS):
		showAchievement(384 + (i * 44), Global.playersAchievements[playerId][i])
		await get_tree().create_timer(0.18).timeout

func showAchievement(y: int, achievement: Global.AchiEnum) -> void:
	var nameLabel = Res.CustomLabelObject.instantiate()
	nameLabel.position = Vector2(170, y)
	nameLabel.text = Global.ACHIEVEMENTS[achievement][0]
	nameLabel.fontSize = 2
	nameLabel.alignment = Control.LayoutPreset.PRESET_CENTER
	nameLabel.animation = 'boom_in'
	nameLabel.audio = Res.AudioPlayerDash.pick_random()
	$Container.add_child(nameLabel)
	var descriptionLabel = Res.CustomLabelObject.instantiate()
	descriptionLabel.position = Vector2(170, y + 18)
	descriptionLabel.text = Global.ACHIEVEMENTS[achievement][1]
	descriptionLabel.fontSize = 1
	descriptionLabel.alignment = Control.LayoutPreset.PRESET_CENTER
	descriptionLabel.animation = 'boom_in'
	$Container.add_child(descriptionLabel)
	
	score += 100
	tweenScore(score)

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
	# Host pre-computes (see Net.host_start_match); guests render transmitted
	# lists, everyone else derives identically from synced match data.
	if Net.isOnline and not Net.isHost:
		return
	Global.finalizeAchievements(playerId)

func _process(delta):
	$Container/MoneyLabel.setText(str(scoreCurr))
