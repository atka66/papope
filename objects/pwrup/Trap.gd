extends Area2D

var armed = false

func _ready():
	yield(get_tree().create_timer(1.0), "timeout")
	armed = true
	$Sprite.hide()

func _on_Trap_body_entered(body):
	if armed && body.is_in_group('players'):
		armed = false
		$Sprite.frame = 1
		$Sprite.show()
		var bodyTrap = body.trap()
		yield(get_tree().create_timer(2.0), "timeout")
		queue_free()
