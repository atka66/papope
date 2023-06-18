extends Node2D

func _ready():
	$Anim.play("fade_in")
	get_node('/root/Music').play('menu')

func _process(delta):
	pass
