extends RigidBody2D

@export var playerId: int = 0
var silent: bool = false

var alive = true
var trapped = false

var thrust: Vector2 = Vector2.ZERO
var speed: int = 20
var frictionCustom = 0.1

var color: Color = Global.TEAM_COLORS[0]

# Called when the node enters the scene tree for the first time.
func _ready():
	color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$BodyParts/Body.modulate = color
	
	if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		$BodyParts/Face.frame = 6
	else:
		$BodyParts/Face.frame = Global.playersSkin[playerId]

func _input(event):
	var lhAxis = Input.get_joy_axis(playerId, JOY_AXIS_LEFT_X)
	var lvAxis = Input.get_joy_axis(playerId, JOY_AXIS_LEFT_Y)
	if abs(lhAxis) < 0.1:
		lhAxis = 0.0
	if abs(lvAxis) < 0.1:
		lvAxis = 0.0

	thrust = Vector2(lhAxis, lvAxis) * speed



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	apply_central_impulse(-linear_velocity * frictionCustom)
	if alive && !Global.playersFrozen && !trapped:
		apply_central_impulse(thrust)

func _on_remove(id):
	if playerId == id:
		queue_free()
