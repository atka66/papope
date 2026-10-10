extends StaticBody2D

func _ready():
	# Deterministic variant from tile position: identical on all peers,
	# no shared RNG state needed (online) and stable across runs.
	$Sprite.frame = absi(int(position.x * 12.9898 + position.y * 78.233)) % $Sprite.hframes

func getShot(playerId: int, normal: Vector2) -> void:
	bounce()

func getWhipped(playerId: int, normal: Vector2) -> void:
	bounce()

func bounce():
	$Anim.play('bounce')

func pinch():
	$AudioPinch.stream = Res.AudioContactCactus.pick_random()
	$AudioPinch.play()
