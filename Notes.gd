### TODOs
# * being trapped should be indicated
# * perks (??s might be discarded)
#     # positive
#     * ?? tiny       - size halved     (might be a bugfest)
#     # negative
#     * drunk      - inverted movement and aim
#     * backfire   - fires the opposite direction
#     * slow       - 25% slower movement
#     * large      - size doubled    (might be a bugfest)
#     * no legs    - can only dash
#     * no hands   - cannot use pickups
#     * time bomb  - dies after 20 seconds
#     * slippery   - no friction
#     * nothing    - nothing happened
#     * amnesia    - previous perks removed
#     * chicken    - you are a chicken

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
