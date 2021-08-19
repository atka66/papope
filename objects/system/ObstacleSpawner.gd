extends Node2D

func _ready():
	spawnObstacle()

func spawnObstacle():
	yield(get_tree().create_timer((randf() * 30) + 1), "timeout")
	var destructible = Res.Destructible.instance()
	destructible.position = position
	destructible.sprite = Res.SpriteDestructibleCrate
	destructible.particleSprite = Res.SpriteDestructibleParticleCrate
	get_parent().add_child(destructible)
	var rerun = spawnObstacle()
