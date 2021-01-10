### TODOs
# * palette change on ship map
# * perks
#     * vampire - dealing damage heals
#     * regeneration - regenerates health over time
#     * [TO BE DISCARDED] no hands
#     * [DISCARDED] ethereal - pass through players
#     * [DISCARDED] tiny     - size halved   (might be a bugfest)
#     * [DISCARDED] large    - size doubled  (too tight in pacman man)
#     * [DISCARDED] slippery   - no friction (speed limit is needed)

### Layers
#
# {Scenes}
# {_Scenes but not by Z setting_}
# [Nodes]
#
# -103 : {MapController}
# -55  : [BgNode], [MovingBackground]
# -54  : [Stars]
# -53  : [Comets]
# -51  : [BgTiles1]
# -50  : [BgTiles2]
# -49  : [BackgroundDim]
# -2   : {PlayerSpawner}, {PwrupSpawner}, {Block}, {WaterTrigger}, {SpaceTrigger}, {Lava}, {TrafficLane}
# -1   : {Dynamite}, {Trap}, {RevolverRay}, {PlayerSlot}, [FeatherPar]
# 0    : {Player}
# 1    : {Tree}, {Mast}, {Cactus}
# 2    : {Car}
# 3    : {Pwrup}, [WhiplashAnim]
# 4    : {Ghost}, {DeadGhost}
# 5    : {SpawnAnim}, {CollisionAnim}, {DespawnAnim}, {ExplosionAnim}, {WhipcrackAnim}
# 6    : [EmberParticles], {Spaceray}
# 50   : [FgTiles1]
# 80   : [ShaderNode], {_WorldEnvironment_}
# 89   : [Crosshair]
# 90   : {Hud}
# 91   : {HudRevolver}, {HudAmmo}
# 100  : {Dim}, {PerkOverlay}
# 101  : {CustomLabel}, [LeftArrow], [RightArrow]
