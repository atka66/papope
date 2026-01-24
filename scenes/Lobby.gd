extends Node2D

@onready var _feedbackAnim = $MenuCanvas/FeedbackHolder/Anim
@onready var _feedbackForm = $MenuCanvas/FeedbackHolder/FeedbackPanel/CenterContainer/VBoxContainer
@onready var _feedbackEdit = $MenuCanvas/FeedbackHolder/FeedbackPanel/CenterContainer/VBoxContainer/FeedbackEdit
@onready var _feedbackFinish = $MenuCanvas/FeedbackHolder/FeedbackPanel/CenterContainer/FinishLabel
@onready var _audioSubmit = $MenuCanvas/FeedbackHolder/AudioSubmit

var countdownNode = null

func _ready():
	Global.MusicNode.play('menu')
	$MenuCanvas/VersionLabel.setText(Global.VERSION)
	if ProjectSettings.get("papope/hosted_mode"):
		$MenuCanvas/FullscreenLabel.setText('atka66.itch.io/papope')
	initPlayers()

func _process(delta):
	var hasConnected = Global.playersJoined.has(true)
	
	$Settings.visible = hasConnected
	$MenuCanvas/Hints.visible = !ProjectSettings.get("papope/hosted_mode") && hasConnected

	$InitHolder/WaitingLabel.hide()
	$InitHolder/TeamLimitLabel.hide()
	$InitHolder/StartHolder.hide()
	if Global.playersConnected.count(true) < 2 or Global.playersJoined.count(true) < 2:
		$InitHolder/WaitingLabel.show()
	elif Global.getNumberOfTeams() < 2:
		$InitHolder/TeamLimitLabel.show()
	elif countdownNode == null:
		$InitHolder/StartHolder.show()

func _input(event):
	if event.is_action_pressed("quit") and !OS.has_feature("web"):
		get_tree().quit()
	if Global.DEBUG && !Global.disableHotkeys: 
		if event.is_action_pressed("test1"): 
			for i in range(4):
				if !Global.playersConnected[i]:
					Global.playersConnected[i] = true
					break
				if !Global.playersJoined[i]:
					Global.playersJoined[i] = true
					Global.joinPlayer(i, false)
					break
		if event.is_action_pressed("test2"): 
			for i in range(4):
				if Global.playersConnected[i]:
					if Global.playersJoined[i]:
						Global.playersJoined[i] = false
						Global.leavePlayer(i)
						break
		if event.is_action_pressed("test3"):
			Global.goToMap()

func initPlayers() -> void:
	Global.playersFrozen = false
	Global.playersPoints = [0, 0, 0, 0]
	Global.playersAchievements = [[], [], [], []]
	# for debugging purposes
	#Global.playersAchievements = [[Global.AchiEnum.UNDERDOG, Global.AchiEnum.NO_REFUNDS, Global.AchiEnum.GUNSLINGER, Global.AchiEnum.DAREDEVIL, Global.AchiEnum.TRIPLE_KILL], [Global.AchiEnum.TRIPLE_KILL, Global.AchiEnum.TRIPLE_KILL], [], []]
	Global.playersPerks = [[], [], [], []]
	Global.initPlayerStats()
	
	for i in range(4):
		if ProjectSettings.get("papope/hosted_mode"):
			Global.playersJoined[i] = false
		else:
			if Global.playersConnected[i] && Global.playersJoined[i]:
				Global.joinPlayer(i, true)

func warnCannotStart() -> void:
	$InitHolder/Anim.stop()
	$InitHolder/Anim.play('warn')
	$InitHolder/AudioFail.play()

func startCountdown() -> void:
	var countdown = Res.CountdownObject.instantiate()
	countdown.position = Vector2(680, 256)
	$MenuCanvas.add_child(countdown)
	countdownNode = countdown

func stopCountdown() -> void:
	countdownNode.queue_free()

func restartMovingBackground() -> void:
	$MovingBackground.restartMovingBackground(null)

func _on_feedback_button_toggled(toggled_on):
	if toggled_on:
		_feedbackEdit.text = ""
		feedbackToggle(true)
		_feedbackAnim.play("appear")
	else:
		_feedbackAnim.play_backwards("appear")

func feedbackToggle(toggled_on: bool):
	_feedbackForm.visible = toggled_on
	_feedbackFinish.visible = !toggled_on


func _on_submit_button_pressed():
	if _feedbackEdit.text.length() < 1:
		return

	var explosion = Res.ExplosionAnimObject.instantiate()
	explosion.position = $Camera.offset + get_viewport().get_mouse_position()
	explosion.harmful = false
	explosion.shakePwr = 30
	Global.addToScene(explosion)

	feedbackToggle(false)
	submitFeedback(_feedbackEdit.text)

func submitFeedback(feedback: String):
	var request = HTTPRequest.new()
	add_child(request)
	var body = JSON.stringify({ 'feedback': feedback, 'source': 'PAPOPE' })
	request.request(Global.FEEDBACK_URL, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	var response = await request.request_completed
	request.queue_free()


func _on_feedback_edit_focus_entered():
	Global.disableHotkeys = true

func _on_feedback_edit_focus_exited():
	Global.disableHotkeys = false
