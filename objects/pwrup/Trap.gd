extends Area2D

var armed = false
var originPlayerId = 0

func _ready():
	yield(get_tree().create_timer(1.0), "timeout")
	armed = true
	$Sprite.hide()

func _on_Trap_body_entered(body):
	if armed:
		if body.is_in_group('dynamites'):
			body.explode()
			var trigger = trigger()
		if body.is_in_group('players'):
			if body.wouldRighteouslyBeHitBy(originPlayerId):
				Global.incrementStat(originPlayerId, Global.StatEnum.TRP_HIT, 1)
			if body.alive && body.playerId == originPlayerId:
				Global.registerAchievement(originPlayerId, Global.AchiEnum.CARELESS)
			body.hurt(35)
			if body.wasJustKilled(body) && !body.isTeammate(originPlayerId):
				Global.addKill(originPlayerId)
			var bodyTrap = body.trap()
			var trigger = trigger()


func _on_Trap_area_entered(area):
	if armed:
		if area.is_in_group('ghosts'):
			Global.incrementStat(originPlayerId, Global.StatEnum.GHOST_KILL, 1)
			area.die()
			var trigger = trigger()

func trigger():
	$Audio.stream = Res.AudioWhipHuts[randi() % len(Res.AudioWhipHuts)]
	$Audio.play()
	armed = false
	$Sprite.frame = 1
	$Sprite.show()
	yield(get_tree().create_timer(2.0), "timeout")
	queue_free()
