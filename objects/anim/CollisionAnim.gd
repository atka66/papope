extends AnimatedSprite

func _on_CollisionAnim_animation_finished():
	queue_free()
