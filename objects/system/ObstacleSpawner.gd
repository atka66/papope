extends Node2D

export(int) var height = 320

func _ready():
	spawnCrate()
	spawnCrateParticle()

func spawnCrate():
	yield(get_tree().create_timer((randf() * 2) + 1), "timeout")
	var crate = Res.Destructible.instance()
	crate.position = position
	crate.position.y += randi() % height
	if randi() % 2 == 0:
		crate.sprite = Res.SpriteDestructibleCrate
		crate.particleSprite = Res.SpriteDestructibleParticleCrate
	else:
		crate.sprite = Res.SpriteDestructibleBarrel
		crate.particleSprite = Res.SpriteDestructibleParticleBarrel
	get_parent().add_child(crate)
	var rerun = spawnCrate()

func spawnCrateParticle():
	yield(get_tree().create_timer(randf() * 0.5), "timeout")
	var cratePar = Res.DestructibleParticle.instance()
	cratePar.position = position
	cratePar.position.y += randi() % height
	cratePar.sprite = Res.SpriteDestructibleParticleCrate
	get_parent().add_child(cratePar)
	var rerun = spawnCrateParticle()
