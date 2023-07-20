extends Node2D

func _ready():
	$Sprite.frame = Global.MapControllerNode.determRandom.randi() % $Sprite.hframes
