### TODOs
# * players should jump around when touching lava
# * time bomb perk explosion should be actual explosion
# * achievements
#     * triple kill   - kill 3 enemies in one round
# * perks (??s might be discarded)
#     * long arm      - extended throw and whip distance
#     * [DISCARDED] tiny     - size halved   (might be a bugfest)
#     * [DISCARDED] large    - size doubled  (too tight in pacman man)
#     * ?? slippery   - no friction          (speed limit is needed)
#     * ?? chicken    - you are a chicken    (learn to draw chicken)

### Layers
#
# {Scenes}
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
# -1   : {Dynamite}, {Trap}, {RevolverRay}, {PlayerSlot}
# 0    : {Player}
# 1    : {Tree}, {Mast}, {Cactus}
# 2    : {Car}
# 3    : {Pwrup}, [WhiplashAnim]
# 4    : {Ghost}, {DeadGhost}
# 5    : {SpawnAnim}, {CollisionAnim}, {DespawnAnim}, {ExplosionAnim}, {WhipcrackAnim}
# 6    : [EmberParticles], {Spaceray}
# 50   : [FgTiles1]
# 89   : [Crosshair]
# 90   : {Hud}
# 91   : {HudRevolver}, {HudAmmo}
# 100  : {Dim}, {PerkOverlay}
# 101  : {CustomLabel}, [LeftArrow], [RightArrow]
