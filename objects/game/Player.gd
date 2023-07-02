extends RigidBody2D

@export var playerId: int = 0
@onready var Lobby: Node2D = get_node('/root/Lobby')
var silent: bool = false

var alive: bool = true
var trapped: bool = false
var fallWater: bool = false
var inSpace: bool = false

var thrust: Vector2 = Vector2.ZERO
var speed: int = 20
var dashMultiplier: int = 30
var frictionCustom: float = 0.1

var color: Color = Global.TEAM_COLORS[0]
var inputCd: bool = false

func _ready():
	if !Global.playersCrowned[playerId]:
		$Crown.hide()
	
	color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
	$BodyParts/Body.color = color
	
	if !silent:
		var anim = Res.SpawnPlayerAnimObject.instantiate()
		anim.position = global_position
		get_tree().get_root().add_child(anim)
	
	if Global.playersPerks[playerId].has(Global.PerkEnum.CHICKEN):
		$BodyParts/Face.frame = 6
	else:
		$BodyParts/Face.frame = Global.playersSkin[playerId]

func _input(event):
	var lhAxis: float = Input.get_joy_axis(playerId, JOY_AXIS_LEFT_X)
	var lvAxis: float = Input.get_joy_axis(playerId, JOY_AXIS_LEFT_Y)
	if abs(lhAxis) < 0.1:
		lhAxis = 0.0
	if abs(lvAxis) < 0.1:
		lvAxis = 0.0

	var axis: Vector2 = Vector2(lhAxis, lvAxis)

	thrust = axis * speed

	if event.device == playerId && !inputCd:
		inputCd = true
		if Lobby != null:
			if event.is_action_pressed("skin_next"):
				Global.playersSkin[playerId] = (Global.playersSkin[playerId] + 1) % Global.SKIN_COUNT
				$BodyParts/Face.frame = Global.playersSkin[playerId]
			if ProjectSettings.get("papope/allow_players_set_options"):
					if event.is_action_pressed("game_use"):
						Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 1) % 4
					if event.is_action_pressed("game_dash"):
						Global.playersTeam[playerId] = (Global.playersTeam[playerId] + 3) % 4
					$BodyParts/Body.color = Global.TEAM_COLORS[Global.playersTeam[playerId]]
		else:
			if alive && !Global.playersFrozen && !fallWater:
				if !trapped && linear_velocity.length() < 1000:
					if event.is_action_pressed("game_dash"):
						dash(axis)

func dash(axis: Vector2) -> void:
	$AudioDash.stream = Res.AudioPlayerDash.pick_random()
	$AudioDash.play()
	
	var impulse: Vector2 = linear_velocity.normalized() * speed * dashMultiplier
	apply_central_impulse(impulse)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	inputCd = false

func _physics_process(delta):
	if !inSpace:
		apply_central_impulse(-linear_velocity * frictionCustom)
		if alive && !Global.playersFrozen && !trapped:
			apply_central_impulse(thrust)

func _on_remove(id):
	if playerId == id:
		queue_free()
