extends Node2D

signal finished()

func _ready():
	for i in range(4):
		if !Global.playersJoined[i]:
			get_node('Card' + str(i)).hide()

func _process(delta):
	if $PlayerPerks0.isFinished && $PlayerPerks1.isFinished && $PlayerPerks2.isFinished && $PlayerPerks3.isFinished && !$Anim.is_playing():
		$Anim.play("disappear")

func _on_Anim_animation_finished(anim_name):
	match anim_name:
		'appear':
			$Anim.play("deckappear")
		'disappear':
			emit_signal("finished")
			queue_free()
