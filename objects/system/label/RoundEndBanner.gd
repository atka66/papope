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
	if Net.isOnline:
		# Host advances everyone to the next round together; clients wait.
		if multiplayer.is_server():
			Net.host_start_match()
	else:
		Global.goToMap()
