extends Node2D

onready var CustomLabel = preload("res://objects/system/CustomLabel.tscn")
onready var FallingMessage = preload("res://objects/system/FallingMessage.tscn")
onready var Player = preload("res://objects/Player.tscn")
onready var Hud = preload("res://objects/hud/Hud.tscn")
onready var Dim = preload("res://objects/system/Dim.tscn")
onready var Countdown = preload("res://objects/system/Countdown.tscn")
onready var Pwrup = preload("res://objects/pwrup/Pwrup.tscn")
onready var CollisionAnim = preload("res://objects/anim/CollisionAnim.tscn")
onready var SpawnAnim = preload("res://objects/anim/SpawnAnim.tscn")
onready var DespawnAnim = preload("res://objects/anim/DespawnAnim.tscn")
onready var WhipcrackAnim = preload("res://objects/anim/WhipcrackAnim.tscn")
onready var ExplosionAnim = preload("res://objects/anim/ExplosionAnim.tscn")
onready var RevolverRay = preload("res://objects/pwrup/RevolverRay.tscn")
onready var RevolverRicochet = preload("res://objects/pwrup/RevolverRicochet.tscn")
onready var Dynamite = preload("res://objects/pwrup/Dynamite.tscn")
onready var Trap = preload("res://objects/pwrup/Trap.tscn")
onready var Car = preload("res://objects/obstacle/Car.tscn")

onready var AudioMsg = preload("res://sounds/system/msg.ogg")
onready var AudioOption = preload("res://sounds/system/option.ogg")
onready var AudioRoundStart = preload("res://sounds/system/round_start.ogg")
onready var AudioRoundGo = preload("res://sounds/system/round_go.ogg")
onready var AudioWinner = preload("res://sounds/system/winner.ogg")
onready var AudioSpacerayStart = preload("res://sounds/spaceray/start_alter.ogg")
onready var AudioSpacerayStop = preload("res://sounds/spaceray/stop.ogg")
onready var AudioPwrupPickup = preload("res://sounds/pwrup/pickup.ogg")
onready var AudioRevRicochet = [
	preload("res://sounds/pwrup/rev_ricochet_1.ogg"),
	preload("res://sounds/pwrup/rev_ricochet_2.ogg"),
	preload("res://sounds/pwrup/rev_ricochet_3.ogg")
]
onready var AudioShieldStart = preload("res://sounds/pwrup/shield_start.ogg")
onready var AudioShieldEnd = preload("res://sounds/pwrup/shield_end.ogg")
onready var AudioWhipHuts = [
	preload("res://sounds/pwrup/whip_huts_1.ogg"),
	preload("res://sounds/pwrup/whip_huts_2.ogg"),
	preload("res://sounds/pwrup/whip_huts_3.ogg")
]
onready var AudioPlayerDash = [
	preload("res://sounds/player/dash_1.ogg"),
	preload("res://sounds/player/dash_2.ogg"),
	preload("res://sounds/player/dash_3.ogg")
]
onready var AudioPlayerHurtCactus = [
	preload("res://sounds/player/hurt_cactus_1.ogg"),
	preload("res://sounds/player/hurt_cactus_2.ogg")
]
onready var AudioPlayerDeath = preload("res://sounds/player/death.ogg")
onready var AudioCollisionBlock = preload("res://sounds/collision/block.ogg")
onready var AudioCollisionCar = [
	preload("res://sounds/collision/car_1.ogg"),
	preload("res://sounds/collision/car_2.ogg"),
	preload("res://sounds/collision/car_3.ogg")
]
onready var AudioCollisionPlayer = [
	preload("res://sounds/collision/player_1.ogg"),
	preload("res://sounds/collision/player_2.ogg"),
	preload("res://sounds/collision/player_3.ogg")
]

onready var PwrupSprites = {
	'revolver' : preload("res://sprites/pwrup/pwrup_revolver.tres"),
	'dynamite' : preload("res://sprites/pwrup/pwrup_dynamite.tres"),
	'shield' : preload("res://sprites/pwrup/pwrup_shield.tres"),
	'trap' : preload("res://sprites/pwrup/pwrup_trap.tres"),
	'whip' : preload("res://sprites/pwrup/pwrup_whip.tres")
}
