### TODOs
# * new gamemode (perks)
#   * in perks mode players get a perk card from a set of randomized perk cards before each round
#   * these perks will stay with them until the end of the game (stacking every round)
#   * perks can be both advantageous and disadvantageous
#   * planned perks:
#     # positive
#     * akimbo     - pickups are doubled
#     * thick      - incoming damage halved
#     * speed      - 50% faster movement
#     * thorns     - collision damages others
#     * tiny       - size halved
#     * cuddles    - collision heals self
#     # negative
#     * drunk      - inverted movement and aim
#     * backfire   - fires the opposite direction
#     * slow       - 25% slower movement
#     * large      - size doubled
#     * no legs    - can only dash
#     * no hands   - cannot pick up pickups
#     * time bomb  - dies after 20 seconds
#     * slippery   - no friction

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
