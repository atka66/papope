extends Camera2D

const center: Vector2 = Vector2(680, 384)

var shakePwr: int = 0

var cameraShakeOffset: Vector2 = Vector2.ZERO
var cameraPlayersOffset: Vector2 = Vector2.ZERO

func _ready():
	Global.CameraNode = self
	make_current()

func _process(delta):
	calculatePlayersOffset()
	calculateShakeOffset()
	position = cameraPlayersOffset + cameraShakeOffset

func calculatePlayersOffset():
	var playerDiff: Vector2 = Vector2.ZERO
	
	var players: Array = get_tree().get_nodes_in_group('players').filter(func(player): return player.alive)
	if !players.is_empty():
		for player in players:
			var playerPos: Vector2 = player.global_position - center
			playerDiff += playerPos.normalized() * pow(playerPos.length(), 0.7)
		playerDiff /= len(players)
	var offsetStep: Vector2 = (playerDiff - cameraPlayersOffset)
	cameraPlayersOffset = cameraPlayersOffset + offsetStep

func calculateShakeOffset():
	if shakePwr > 0:
		cameraShakeOffset = Vector2((randi() % (shakePwr * 2)) - shakePwr, (randi() % (shakePwr * 2)) - shakePwr)
		shakePwr -= 1
	else:
		cameraShakeOffset = Vector2.ZERO
