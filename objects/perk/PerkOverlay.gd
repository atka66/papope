extends Node2D

signal finished()

func _process(delta):
	if $PlayerPerks0.isFinished && $PlayerPerks1.isFinished && $PlayerPerks2.isFinished && $PlayerPerks3.isFinished && !$Anim.is_playing():
		$Anim.play("disappear")

func _on_Anim_animation_finished(anim_name):
	if anim_name == 'disappear':
		emit_signal("finished")
		queue_free()
