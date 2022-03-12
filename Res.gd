extends Node2D

onready var CustomLabel = preload("res://objects/system/label/CustomLabel.tscn")
onready var FallingMessage = preload("res://objects/system/label/FallingMessage.tscn")
onready var RoundStartBanner = preload("res://objects/system/label/RoundStartBanner.tscn")
onready var RoundEndBanner = preload("res://objects/system/label/RoundEndBanner.tscn")
onready var Player = preload("res://objects/Player.tscn")
onready var Hud = preload("res://objects/hud/Hud.tscn")
onready var Perk = preload("res://objects/hud/Perk.tscn")
onready var PerkOverlay = preload("res://objects/perk/PerkOverlay.tscn")
onready var PerkCard = preload("res://objects/perk/PerkCard.tscn")
onready var PerkSlot = preload("res://objects/perk/PerkSlot.tscn")
onready var Dim = preload("res://objects/system/Dim.tscn")
onready var Countdown = preload("res://objects/system/label/Countdown.tscn")
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
onready var Ghost = preload("res://objects/obstacle/Ghost.tscn")
onready var DeadGhost = preload("res://objects/obstacle/DeadGhost.tscn")
onready var FeatherPar = preload("res://objects/anim/FeatherPar.tscn")
onready var DashPar = preload("res://objects/anim/DashPar.tscn")
onready var Destructible = preload("res://objects/obstacle/Destructible.tscn")
onready var DestructibleParticle = preload("res://objects/obstacle/DestructibleParticle.tscn")

onready var SpriteDestructibleCrate = preload("res://sprites/obstacle/crate.png")
onready var SpriteDestructibleParticleCrate = preload("res://sprites/obstacle/crate_particle.png")
onready var SpriteDestructibleBarrel = preload("res://sprites/obstacle/barrel.png")
onready var SpriteDestructibleParticleBarrel = preload("res://sprites/obstacle/barrel_particle.png")

onready var AudioOption = preload("res://sounds/system/option.ogg")
onready var AudioRoundGo = preload("res://sounds/system/round_go.ogg")
onready var AudioSpacerayStart = preload("res://sounds/spaceray/start.ogg")
onready var AudioSpacerayOngoing = preload("res://sounds/spaceray/ongoing.ogg")
onready var AudioSpacerayStop = preload("res://sounds/spaceray/stop.ogg")
onready var AudioPwrupPickup = preload("res://sounds/pwrup/pickup.ogg")
onready var AudioRevFire = preload("res://sounds/pwrup/rev_fire.ogg")
onready var AudioRevRicochet = [
	preload("res://sounds/pwrup/rev_ricochet_1.ogg"),
	preload("res://sounds/pwrup/rev_ricochet_2.ogg"),
	preload("res://sounds/pwrup/rev_ricochet_3.ogg")
]
onready var AudioExplode = [
	preload("res://sounds/pwrup/explode_1.ogg"),
	preload("res://sounds/pwrup/explode_2.ogg"),
	preload("res://sounds/pwrup/explode_3.ogg")
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
onready var AudioCardFlip = [
	preload("res://sounds/perk/flip_1.ogg"),
	preload("res://sounds/perk/flip_2.ogg"),
	preload("res://sounds/perk/flip_3.ogg")
]
onready var AudioChickenIdle = [
	preload("res://sounds/chicken/idle_1.ogg"),
	preload("res://sounds/chicken/idle_2.ogg"),
	preload("res://sounds/chicken/idle_3.ogg")
]
onready var AudioChickenHurt = [
	preload("res://sounds/chicken/hurt_1.ogg"),
	preload("res://sounds/chicken/hurt_2.ogg"),
	preload("res://sounds/chicken/hurt_3.ogg")
]
onready var AudioDestructibleDestroy = [
	preload("res://sounds/destructible/destroy_1.wav"),
	preload("res://sounds/destructible/destroy_2.wav"),
	preload("res://sounds/destructible/destroy_3.wav")
]
onready var AudioCarHorn = [
	preload("res://sounds/collision/car_horn_1.ogg"),
	preload("res://sounds/collision/car_horn_2.ogg"),
	preload("res://sounds/collision/car_horn_3.ogg"),
	preload("res://sounds/collision/car_horn_4.ogg"),
	preload("res://sounds/collision/car_horn_5.ogg"),
	preload("res://sounds/collision/car_horn_6.ogg")
]

onready var PwrupSprites = {
	'revolver' : preload("res://sprites/pwrup/pwrup_revolver.tres"),
	'dynamite' : preload("res://sprites/pwrup/pwrup_dynamite.tres"),
	'shield' : preload("res://sprites/pwrup/pwrup_shield.tres"),
	'trap' : preload("res://sprites/pwrup/pwrup_trap.tres"),
	'whip' : preload("res://sprites/pwrup/pwrup_whip.tres")
}

# Music

onready var MusicNode = preload("res://objects/system/Music.tscn")
onready var AudioMusicDefault = preload("res://music/default.ogg")
onready var AudioMusicLobby = preload("res://music/lobby.ogg")
onready var AudioMusicPostGame = preload("res://music/postgame.ogg")
onready var AudioMusicHell = preload("res://music/hell.ogg")
onready var AudioMusicWestern = preload("res://music/western.ogg")
onready var AudioMusicSpace = preload("res://music/space.ogg")
onready var AudioMusicConveyor = preload("res://music/conveyor.ogg")
