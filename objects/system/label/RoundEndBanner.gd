extends Node2D

@export var aliveTeamId: int = 0

func _ready():
	if aliveTeamId != -2:
		#$Team.set_text(Global.TEAM_COLOR_STRINGS[aliveTeamId]) todo these
		#$Team.set_color(Global.TEAM_COLORS[aliveTeamId])
		$Anim.play('wins')
	else:
		$Anim.play('draw')
	
	await $Anim.animation_finished
	Global.goToMap()
