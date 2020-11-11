extends RigidBody2D

export var playerId = 0

var hit = false
var alive = true
var hp = 100
var contactedLava = false
var item = null
var ammo = 0
var hurtByLava = false
var outsideCntdwn = 3
var invulnerable = false
var fallWater = false
var trapped = false
var hurtIntensity = 0.0

var thrust = Vector2.ZERO
var speed = 40
var frictionCustom = 0.2

func _ready():
	$Body.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Face.frame = Global.playersSkin[playerId]
	$SpawnAnim.play()

func _input(event):
	var hAxis = Input.get_joy_axis(playerId, JOY_AXIS_0)
	var vAxis = Input.get_joy_axis(playerId, JOY_AXIS_1)
	if abs(hAxis) < 0.1 : hAxis = 0.0
	if abs(vAxis) < 0.1 : vAxis = 0.0
	thrust = Vector2(hAxis, vAxis) * speed
	
	if event.device == playerId:
		if Input.is_action_just_pressed("pl_skin_next"):
			Global.playersSkin[playerId] = (Global.playersSkin[playerId] + 1) % Global.SKIN_COUNT
		if Input.is_action_just_pressed("pl_skin_prev"):
			Global.playersSkin[playerId] = (Global.playersSkin[playerId] + (Global.SKIN_COUNT - 1)) % Global.SKIN_COUNT
		if Input.is_action_just_pressed("pl_team_next"):
			Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 1) % 4
		if Input.is_action_just_pressed("pl_team_prev"):
			Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 3) % 4
		$Face.frame = Global.playersSkin[playerId]
		$Body.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]

# warning-ignore:unused_argument
func _physics_process(delta):
	#friction
	apply_central_impulse(-linear_velocity * frictionCustom)
	
	apply_central_impulse(thrust)

func _on_remove(id):
	if playerId == id:
		queue_free()

func _on_SpawnAnim_animation_finished():
	$SpawnAnim.hide()

func _on_Player_body_entered(body):
	if body.get_name() == 'Player':
		if !hit:
			body.hit = true
			var collisionAnim = Global.CollisionAnim.instance()
			var animScale = (thrust.length() + body.thrust.length()) / 30
			collisionAnim.scale = Vector2(animScale, animScale)
			collisionAnim.play()
			collisionAnim.position = body.global_position - ((body.global_position - global_position) / 2)
			collisionAnim.look_at(body.global_position)
			Global.Lobby.add_child(collisionAnim)
		apply_central_impulse(body.global_position.direction_to(global_position) * 100)
		hit = false
