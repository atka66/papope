extends Node

@onready var ShaderCacheObject = load("res://objects/system/ShaderCache.tscn")

@onready var CustomLabelObject = load("res://objects/system/label/CustomLabel.tscn")
@onready var RoundEndBannerObject = load("res://objects/system/label/RoundEndBanner.tscn")
@onready var PlayerObject = load("res://objects/game/Player.tscn")
@onready var HudObject = load("res://objects/game/hud/Hud.tscn")
@onready var PwrupObject = load("res://objects/game/pwrup/Pwrup.tscn")
@onready var RevolverRayObject = load("res://objects/game/pwrup/RevolverRay.tscn")
@onready var DynamiteObject = load("res://objects/game/pwrup/Dynamite.tscn")
@onready var TrapObject = load("res://objects/game/pwrup/Trap.tscn")
@onready var WhiplashObject = load("res://objects/game/pwrup/Whiplash.tscn")
@onready var SpawnPlayerAnimObject = load("res://objects/anim/SpawnPlayerAnim.tscn")
@onready var SpawnPwrupAnimObject = load("res://objects/anim/SpawnPwrupAnim.tscn")
@onready var RevolverRicochetAnimObject = load("res://objects/anim/RevolverRicochet.tscn")
@onready var ExplosionAnimObject = load("res://objects/anim/ExplosionAnim.tscn")
@onready var CrackAnimObject = load("res://objects/anim/CrackAnim.tscn")
@onready var CollisionAnimObject = load("res://objects/anim/CollisionAnim.tscn")
@onready var CountdownObject = load("res://objects/system/label/Countdown.tscn")
@onready var GhostObject = load("res://objects/game/entity/Ghost.tscn")
@onready var DeadGhostObject = load("res://objects/game/entity/DeadGhost.tscn")
@onready var CarObject = load("res://objects/game/entity/Car.tscn")
@onready var DashParticlesObject = load("res://objects/anim/DashParticles.tscn")
@onready var FeatherParticlesObject = load("res://objects/anim/FeatherParticles.tscn")
@onready var FallingLabelObject = load("res://objects/system/label/FallingLabel.tscn")

@onready var PerkOverlayObject = load("res://objects/system/perk/PerkOverlay.tscn")
@onready var PerkSlotObject = load("res://objects/system/perk/PerkSlot.tscn")
@onready var PerkCardObject = load("res://objects/system/perk/PerkCard.tscn")

@onready var AudioRoundGo = load("res://audio/sfx/system/round_go.ogg")

@onready var AudioRevolverFire = load("res://audio/sfx/pwrup/rev_fire.ogg")
@onready var AudioRevolverRicochet = [
	load("res://audio/sfx/pwrup/rev_ricochet_1.ogg"),
	load("res://audio/sfx/pwrup/rev_ricochet_2.ogg"),
	load("res://audio/sfx/pwrup/rev_ricochet_3.ogg")
]
@onready var AudioExplosion = [
	load("res://audio/sfx/pwrup/explode_1.ogg"),
	load("res://audio/sfx/pwrup/explode_2.ogg"),
	load("res://audio/sfx/pwrup/explode_3.ogg")
]
@onready var AudioWhipHuts = [
	load("res://audio/sfx/pwrup/whip_huts_1.ogg"),
	load("res://audio/sfx/pwrup/whip_huts_2.ogg"),
	load("res://audio/sfx/pwrup/whip_huts_3.ogg")
]
@onready var AudioPlayerDash = [
	load("res://audio/sfx/player/dash_1.ogg"),
	load("res://audio/sfx/player/dash_2.ogg"),
	load("res://audio/sfx/player/dash_3.ogg")
]

@onready var AudioHurtDynamite = load("res://audio/sfx/player/hurt/hurt_dynamite.ogg")
@onready var AudioHurtTrap = load("res://audio/sfx/player/hurt/hurt_trap.ogg")
@onready var AudioHurtWhip = load("res://audio/sfx/player/hurt/hurt_whip.ogg")
@onready var AudioHurtScare = load("res://audio/sfx/player/hurt/hurt_scare.ogg")

@onready var AudioLava = load("res://audio/sfx/player/lava_enter.ogg")

@onready var AudioContactPlayer = [
	load("res://audio/sfx/contact/player_collide_1.ogg"),
	load("res://audio/sfx/contact/player_collide_2.ogg"),
	load("res://audio/sfx/contact/player_collide_3.ogg")
]
@onready var AudioContactCactus = [
	load("res://audio/sfx/contact/cactus_contact_1.ogg"),
	load("res://audio/sfx/contact/cactus_contact_2.ogg")
]

@onready var AudioContactCar = [
	load("res://audio/sfx/entity/car_1.ogg"),
	load("res://audio/sfx/entity/car_2.ogg"),
	load("res://audio/sfx/entity/car_3.ogg")
]
@onready var AudioCarHorn = [
	load("res://audio/sfx/entity/car_horn_1.ogg"),
	load("res://audio/sfx/entity/car_horn_2.ogg"),
	load("res://audio/sfx/entity/car_horn_3.ogg"),
	load("res://audio/sfx/entity/car_horn_4.ogg"),
	load("res://audio/sfx/entity/car_horn_5.ogg"),
	load("res://audio/sfx/entity/car_horn_6.ogg")
]

@onready var AudioCardFlip = [
	load("res://audio/sfx/system/perk/flip_1.ogg"),
	load("res://audio/sfx/system/perk/flip_2.ogg"),
	load("res://audio/sfx/system/perk/flip_3.ogg")
]
@onready var AudioChickenIdle = [
	load("res://audio/sfx/player/chicken_idle_1.ogg"),
	load("res://audio/sfx/player/chicken_idle_2.ogg"),
	load("res://audio/sfx/player/chicken_idle_3.ogg")
]
@onready var AudioChickenHurt = [
	load("res://audio/sfx/player/hurt/chicken_hurt_1.ogg"),
	load("res://audio/sfx/player/hurt/chicken_hurt_2.ogg"),
	load("res://audio/sfx/player/hurt/chicken_hurt_3.ogg")
]

@onready var AudioMusicDefault = load("res://audio/music/default.ogg")
@onready var AudioMusicSplash = load("res://audio/music/splash.ogg")
@onready var AudioMusicLobby = load("res://audio/music/lobby.ogg")
@onready var AudioMusicPostGame = load("res://audio/music/postgame.ogg")
@onready var AudioMusicHell = load("res://audio/music/hell.ogg")
@onready var AudioMusicWestern = load("res://audio/music/western.ogg")
@onready var AudioMusicSpace = load("res://audio/music/space.ogg")
@onready var AudioMusicIndustrial = load("res://audio/music/industrial.ogg")

@onready var TexturePerks = load("res://sprites/perk/perks.png")
