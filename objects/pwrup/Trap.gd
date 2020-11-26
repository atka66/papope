extends Area2D

var armed = false
var originPlayerId = 0

func _ready():
	yield(get_tree().create_timer(1.0), "timeout")
	armed = true
	$Sprite.hide()

func _on_Trap_body_entered(body):
	if armed && body.is_in_group('players'):
		armed = false
		$Sprite.frame = 1
		$Sprite.show()
		if body.wouldRighteouslyBeHitBy(originPlayerId):
			Global.incrementStat(originPlayerId, Global.Stat.TRP_HIT, 1)
		if body.alive && body.playerId == originPlayerId:
			Global.registerAchievement(originPlayerId, Global.Achi.CARELESS)
		body.hurt(35)
		var bodyTrap = body.trap()
		yield(get_tree().create_timer(2.0), "timeout")
		queue_free()
