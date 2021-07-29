tool
extends StaticBody2D

export(Texture) var sprite
export(Texture) var particleSprite
export(int) var collisionSize = 16
export(int) var spriteOffset

var hp = 6

func _ready():
	$Sprite.texture = sprite
	$Sprite.offset.y = spriteOffset
	$CollisionShape2D.shape.set_extents(Vector2(collisionSize, collisionSize))

func destroy(impulse):
	for i in range(15):
		var particle = Res.DestructibleParticle.instance()
		particle.get_node('Sprite').texture = particleSprite
		particle.position = position + Vector2((randi() % 32) - 16, (randi() % 32) - 16)
		particle.impulse(impulse)
		get_parent().add_child(particle)
	queue_free()
