extends Node2D

signal finished()

func _ready():
	modulate.a = 0
	for i in range(4):
		if !Global.playersJoined[i]:
			get_node('Card' + str(i)).hide()
			pass
	
	await get_tree().create_timer(1.5).timeout
	$Anim.play("appear")

func _process(delta):
	if $PlayerPerks0.isFinished && $PlayerPerks1.isFinished && $PlayerPerks2.isFinished && $PlayerPerks3.isFinished && !$Anim.is_playing():
		$Anim.play("disappear")

func playToss(card: int):
	if Global.playersJoined[card]:
		var audioNode = get_node('Card' + str(card)).get_node('AudioToss')
		audioNode.stream = Res.AudioPlayerDash.pick_random()
		audioNode.play()

func _on_anim_animation_finished(anim_name):
	match anim_name:
		'appear':
			$Anim.play("deckappear")
			$AudioDeckAppear.play()
		'disappear':
			emit_signal("finished")
			queue_free()
