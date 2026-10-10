extends StaticBody2D

func _ready():
	# Deterministic variant from tile position: identical on all peers,
	# no shared RNG state needed (online) and stable across runs.
	$Sprite.frame = absi(int(position.x * 12.9898 + position.y * 78.233)) % $Sprite.hframes
