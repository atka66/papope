extends Area2D

@export var type: Global.PwrupEnum = Global.PwrupEnum.DYNAMITE

# Called when the node enters the scene tree for the first time.
func _ready():
	match type:
		Global.PwrupEnum.DYNAMITE:
			$Sprite.animation = 'dynamite'
		Global.PwrupEnum.REVOLVER:
			$Sprite.animation = 'revolver'
		Global.PwrupEnum.SHIELD:
			$Sprite.animation = 'shield'
		Global.PwrupEnum.TRAP:
			$Sprite.animation = 'trap'
		Global.PwrupEnum.WHIP:
			$Sprite.animation = 'whip'


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
