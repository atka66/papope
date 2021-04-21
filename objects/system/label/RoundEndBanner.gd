extends Node2D

export(int) var aliveTeamId = 0

func _ready():
	if aliveTeamId != -2:
		$Team.set_text(Global.TEAM_COLOR_STRINGS[aliveTeamId])
		$Team.set_color(Global.TEAM_COLORS[aliveTeamId])
		$Draw.hide()
		$Anim.play('wins')
	else:
		$Team.hide()
		$Wins.hide()
		$Anim.play('draw')

func _on_Anim_animation_finished(anim_name):
	Global.goToMap()
