extends Node2D

func _ready():
	restartMovingBackground(null)

func restartMovingBackground(anim_name) -> void:
	var resultFrame = ($Backgrounds.frame + (randi() % ($Backgrounds.sprite_frames.get_frame_count('default') - 1)) + 1) % $Backgrounds.sprite_frames.get_frame_count('default')
	match Global.options['map'][Global.optionsSelected['map']]:
		'hell':
			resultFrame = 0
		'western':
			resultFrame = 1
		'ship':
			resultFrame = 2
		'space':
			resultFrame = 3
		'highway':
			resultFrame = 4
		'pacman':
			resultFrame = 5
		'industrial':
			resultFrame = 6
	$Backgrounds.frame = resultFrame
	#TODO redo images
	
	$Anim.seek(0)
	$Anim.play("loop")
