extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.movingBackground = self
	restartMovingBackground(null)

func determineBackground():
	var resultFrame = ($Background.frame + (randi() % ($Background.frames.get_frame_count('default') - 1)) + 1) % $Background.frames.get_frame_count('default')
	if Global.playersJoined.has(true):
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
			'conveyor':
				resultFrame = 6
	$Background.frame = resultFrame

func restartMovingBackground(anim_name):
	determineBackground()
	$Anim.seek(0)
	$Anim.play('loop')
