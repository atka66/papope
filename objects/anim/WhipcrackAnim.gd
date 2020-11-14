extends AnimatedSprite

func _ready():
	play()

func _on_WhipcrackAnim_animation_finished():
	queue_free()
