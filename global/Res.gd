extends Node

@onready var CustomLabelObject = preload("res://objects/system/label/CustomLabel.tscn")
@onready var RoundEndBannerObject = preload("res://objects/system/label/RoundEndBanner.tscn")
@onready var PlayerObject = preload("res://objects/game/Player.tscn")
@onready var HudObject = preload("res://objects/game/hud/Hud.tscn")
@onready var PwrupObject = preload("res://objects/game/pwrup/Pwrup.tscn")
@onready var RevolverRayObject = preload("res://objects/game/pwrup/RevolverRay.tscn")
@onready var DynamiteObject = preload("res://objects/game/pwrup/Dynamite.tscn")
@onready var TrapObject = preload("res://objects/game/pwrup/Trap.tscn")
@onready var WhiplashObject = preload("res://objects/game/pwrup/Whiplash.tscn")
@onready var SpawnPlayerAnimObject = preload("res://objects/anim/SpawnPlayerAnim.tscn")
@onready var SpawnPwrupAnimObject = preload("res://objects/anim/SpawnPwrupAnim.tscn")
@onready var RevolverRicochetAnimObject = preload("res://objects/anim/RevolverRicochet.tscn")
@onready var ExplosionAnimObject = preload("res://objects/anim/ExplosionAnim.tscn")
@onready var CrackAnimObject = preload("res://objects/anim/CrackAnim.tscn")
@onready var CollisionAnimObject = preload("res://objects/anim/CollisionAnim.tscn")
@onready var CountdownObject = preload("res://objects/system/label/Countdown.tscn")
@onready var GhostObject = preload("res://objects/game/entity/Ghost.tscn")
@onready var DeadGhostObject = preload("res://objects/game/entity/DeadGhost.tscn")
@onready var CarObject = preload("res://objects/game/entity/Car.tscn")
@onready var DashParticlesObject = preload("res://objects/anim/DashParticles.tscn")

@onready var AudioRoundGo = preload("res://audio/sfx/system/round_go.ogg")

@onready var AudioPlayerCollide = [
	preload("res://audio/sfx/player/collide_1.ogg"),
	preload("res://audio/sfx/player/collide_2.ogg"),
	preload("res://audio/sfx/player/collide_3.ogg")
]
@onready var AudioRevolverFire = preload("res://audio/sfx/pwrup/rev_fire.ogg")
@onready var AudioRevolverRicochet = [
	preload("res://audio/sfx/pwrup/rev_ricochet_1.ogg"),
	preload("res://audio/sfx/pwrup/rev_ricochet_2.ogg"),
	preload("res://audio/sfx/pwrup/rev_ricochet_3.ogg")
]
@onready var AudioExplosion = [
	preload("res://audio/sfx/pwrup/explode_1.ogg"),
	preload("res://audio/sfx/pwrup/explode_2.ogg"),
	preload("res://audio/sfx/pwrup/explode_3.ogg")
]
@onready var AudioWhipHuts = [
	preload("res://audio/sfx/pwrup/whip_huts_1.ogg"),
	preload("res://audio/sfx/pwrup/whip_huts_2.ogg"),
	preload("res://audio/sfx/pwrup/whip_huts_3.ogg")
]
@onready var AudioPlayerDash = [
	preload("res://audio/sfx/player/dash_1.ogg"),
	preload("res://audio/sfx/player/dash_2.ogg"),
	preload("res://audio/sfx/player/dash_3.ogg")
]

@onready var AudioPlayerDeath = preload("res://audio/sfx/player/death.ogg")
@onready var AudioPlayerDeathWater = preload("res://audio/sfx/player/fall_water.ogg")

@onready var AudioHurtRevolver = preload("res://audio/sfx/player/hurt_revolver.ogg")
@onready var AudioHurtDynamite = preload("res://audio/sfx/player/hurt_dynamite.ogg")
@onready var AudioHurtWhip = preload("res://audio/sfx/player/hurt_whip.ogg")
@onready var AudioHurtTrap = preload("res://audio/sfx/player/hurt_trap.ogg")
@onready var AudioHurtFall = preload("res://audio/sfx/player/hurt_fall.ogg")
@onready var AudioHurtCactus = [
	preload("res://audio/sfx/player/hurt_cactus_1.ogg"),
	preload("res://audio/sfx/player/hurt_cactus_2.ogg")
]

@onready var AudioCarHorn = [
	preload("res://audio/sfx/entity/car_horn_1.ogg"),
	preload("res://audio/sfx/entity/car_horn_2.ogg"),
	preload("res://audio/sfx/entity/car_horn_3.ogg"),
	preload("res://audio/sfx/entity/car_horn_4.ogg"),
	preload("res://audio/sfx/entity/car_horn_5.ogg"),
	preload("res://audio/sfx/entity/car_horn_6.ogg")
]

@onready var AudioCollisionCar = [
	preload("res://audio/sfx/entity/car_1.ogg"),
	preload("res://audio/sfx/entity/car_2.ogg"),
	preload("res://audio/sfx/entity/car_3.ogg")
]

@onready var AudioMusicDefault = preload("res://audio/music/default.ogg")
@onready var AudioMusicSplash = preload("res://audio/music/splash.ogg")
@onready var AudioMusicLobby = preload("res://audio/music/lobby.ogg")
@onready var AudioMusicPostGame = preload("res://audio/music/postgame.ogg")
@onready var AudioMusicHell = preload("res://audio/music/hell.ogg")
@onready var AudioMusicWestern = preload("res://audio/music/western.ogg")
@onready var AudioMusicSpace = preload("res://audio/music/space.ogg")
@onready var AudioMusicConveyor = preload("res://audio/music/conveyor.ogg")
