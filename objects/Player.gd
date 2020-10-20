extends KinematicBody2D

export var playerId = 0

var velocity = Vector2.ZERO
var speed = 250

func _ready():
	$Body.modulate = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$Face.frame = Global.playersSkin[playerId]

func _input(event):
	var hAxis = Input.get_joy_axis(playerId, JOY_AXIS_0)
	var vAxis = Input.get_joy_axis(playerId, JOY_AXIS_1)
	if abs(hAxis) < 0.1 : hAxis = 0.0
	if abs(vAxis) < 0.1 : vAxis = 0.0
	velocity = Vector2(hAxis, vAxis) * speed
	
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

func _physics_process(delta):
	move_and_slide(velocity)

func _on_remove(id):
	if playerId == id:
		queue_free()