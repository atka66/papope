extends Node2D

func _ready():
	if Net.isOnline:
		# Don't paint defaults pre-sync (flashes a wrong map); the first
		# lobby sync fixates the frame, then pan only.
		$Anim.seek(0)
		$Anim.play("loop")
		return
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
		'nightclub':
			resultFrame = 7
	$Backgrounds.frame = resultFrame
	
	$Anim.seek(0)
	$Anim.play("loop")
