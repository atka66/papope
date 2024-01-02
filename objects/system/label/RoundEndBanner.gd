extends Node2D

@export var aliveTeamId: int = 0

func _ready():
	if aliveTeamId != -2:
		$TeamLabel.text = Global.TEAM_COLOR_STRINGS[aliveTeamId]
		$TeamLabel.fontColor = Global.TEAM_COLORS[aliveTeamId]
		$Anim.play('wins')
	else:
		$Anim.play('draw')
	
	await $Anim.animation_finished
	Global.goToMap()
