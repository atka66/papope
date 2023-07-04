extends Node2D

@export var harmful: bool = true
@export var shakePwr: int = 0
@export var originPlayerId: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.shakeScreen(shakePwr)
	$Smoke.restart()
	$BigBoom.restart()
	$Shards.restart()
	$Audio.stream = Res.AudioExplosion.pick_random()
	$Audio.play()
	# todo harm

func _process(delta):
	if !$BigBoom.emitting && !$Smoke.emitting && !$Shards.emitting:
		queue_free()
