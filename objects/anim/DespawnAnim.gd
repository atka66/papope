extends AnimatedSprite

func _ready():
	play()

func _on_DespawnAnim_animation_finished():
	queue_free()
