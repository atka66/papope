extends RigidBody2D

export var originPlayerId = 0
var wrapPosition = null

func _ready():
	$AudioThrow.play()
	$Sprite.rotation_degrees = randi() % 360
	yield(get_tree().create_timer(1.0), "timeout")
	explode()

func _process(delta):
	$Sprite.rotation_degrees += 10

func explode():
	var explosionAnim = Res.ExplosionAnim.instance()
	explosionAnim.position = position
	explosionAnim.originPlayerId = originPlayerId
	explosionAnim.shakePwr = 10
	get_tree().get_current_scene().add_child(explosionAnim)
	queue_free()

func _on_Dynamite_body_entered(body):
	if body.is_in_group('players') && body.playerId != originPlayerId:
		if body.alive && !body.invulnerable:
			body.get_node('AudioHurtDynamite').play()
		explode()
	if !body.is_in_group('players'):
		$AudioCollision.play()

# handle wrapping on pacman map
func _integrate_forces(state):
	if wrapPosition != null:
		state.transform.origin = wrapPosition
		wrapPosition = null
