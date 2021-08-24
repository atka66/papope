extends Area2D

var armed = false
var originPlayerId = 0

var conveyed = false

func _ready():
	yield(get_tree().create_timer(1.0), "timeout")
	armed = true
	$Sprite.hide()

func _process(delta):
	if conveyed:
		position.x -= Global.CONVEYOR_VEL_AREA

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
			body.hurt(Global.DAMAGE_TRAP)
			if body.playerId != originPlayerId && Global.playersPerks[originPlayerId].has(Global.PerkEnum.VAMPIRE):
				Global.getPlayerNode(originPlayerId).heal(Global.DAMAGE_TRAP)
			if body.wasJustKilled(body):
				body.die(Global.DeathEnum.TRAP)
				if !body.isTeammate(originPlayerId):
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
