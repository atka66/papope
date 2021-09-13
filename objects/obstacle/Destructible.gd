tool
extends Node2D

export(Texture) var sprite
export(Texture) var particleSprite
export(int) var numberOfParticles = 15
export(int) var collisionSize = 16
export(int) var spriteOffset
export(int) var hp = 6

var conveyed = false

func _ready():
	$Sprite.texture = sprite
	$Sprite.offset.y = spriteOffset
	if (has_node('CollisionShape2D')):
		$CollisionShape2D.shape.set_extents(Vector2(collisionSize, collisionSize))

func destroyWithParticles(impulse):
	for i in range(numberOfParticles):
		var particle = Res.DestructibleParticle.instance()
		particle.sprite = particleSprite
		particle.position = position + Vector2((randi() % 32) - 16, (randi() % 32) - 16)
		particle.impulse(impulse)
		get_parent().add_child(particle)
	destroy()
	
func destroy():
	get_tree().get_nodes_in_group('controllers')[0].playDestructibleDestroy()
	queue_free()

func _physics_process(delta):
	if conveyed:
		position.x -= Global.CONVEYOR_VEL_AREA
