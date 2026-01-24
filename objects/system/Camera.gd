extends Camera2D

const center: Vector2 = Vector2(680, 384)
const SHAKE_FADE: int = 7
const OFFSET_FADE: int = 10
const OFFSET_LIMIT: int = 100

var shakePwr: float = 0

func _ready():
	Global.CameraNode = self
	make_current()

func _process(delta):
	var playersOffset = calculatePlayersOffset(delta)
	var shakeOffset = calculateShakeOffset(delta)
	offset = limitOffset(playersOffset + shakeOffset)

func limitOffset(offsetToLimit: Vector2) -> Vector2:
	offsetToLimit.x = clamp(offsetToLimit.x, -OFFSET_LIMIT, OFFSET_LIMIT)
	offsetToLimit.y = clamp(offsetToLimit.y, -OFFSET_LIMIT, OFFSET_LIMIT)
	return offsetToLimit

func calculatePlayersOffset(delta) -> Vector2:
	var playerDiff: Vector2 = Vector2.ZERO
	
	var players: Array = get_tree().get_nodes_in_group('players').filter(func(player): return player.alive)
	if !players.is_empty():
		for player in players:
			var playerPos: Vector2 = player.global_position - center
			playerDiff += playerPos.normalized() * pow(playerPos.length(), 0.7)
		playerDiff /= len(players)
	return Vector2(lerpf(offset.x, playerDiff.x, OFFSET_FADE * delta), lerpf(offset.y, playerDiff.y, OFFSET_FADE * delta))

func calculateShakeOffset(delta) -> Vector2:
	if shakePwr > 0:
		shakePwr = lerpf(shakePwr, 0, SHAKE_FADE * delta)
		return Vector2(randf_range(-shakePwr, shakePwr), randf_range(-shakePwr, shakePwr))
	else:
		return Vector2.ZERO
