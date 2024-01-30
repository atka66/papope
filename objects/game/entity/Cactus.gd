extends StaticBody2D

func _ready():
	$Sprite.frame = Global.MapControllerNode.determRandom.randi() % $Sprite.hframes

func getShot(playerId: int, normal: Vector2) -> void:
	bounce()

func getWhipped(playerId: int, normal: Vector2) -> void:
	bounce()

func bounce():
	$Anim.play('bounce')

func pinch():
	$AudioPinch.stream = Res.AudioContactCactus.pick_random()
	$AudioPinch.play()
