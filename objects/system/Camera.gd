extends Camera2D

const CAMERA_CLAMP = 100

var shakePwr = 0

var cameraShakeOffset = Vector2.ZERO
var cameraPlayersOffset = Vector2.ZERO

func _process(delta):
	calculatePlayersOffset()
	calculateShakeOffset()
	position = cameraPlayersOffset + cameraShakeOffset

func calculatePlayersOffset():
	var center = Vector2(340, 192)
	var playerDiff = Vector2.ZERO
	var rawPlayers = get_tree().get_nodes_in_group('players')
	var players = []
	for player in rawPlayers:
		if player.alive:
			players.append(player)
	if !players.empty():
		for player in players:
			var playerPos = player.global_position - center
			playerDiff += playerPos.normalized() * pow(playerPos.length(), 0.7)
		playerDiff /= len(players)
	var offsetStep = (playerDiff - cameraPlayersOffset) / 4
	cameraPlayersOffset = cameraPlayersOffset + offsetStep
	cameraPlayersOffset = cameraPlayersOffset.clamped(CAMERA_CLAMP)

func calculateShakeOffset():
	if shakePwr > 0:
		cameraShakeOffset = Vector2((randi() % (shakePwr * 2)) - shakePwr, (randi() % (shakePwr * 2)) - shakePwr)
		shakePwr -= 1
	else:
		cameraShakeOffset = Vector2.ZERO
