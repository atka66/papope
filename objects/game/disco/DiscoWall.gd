extends StaticBody2D

# Nightclub dancefloor wall: the neon ring around the lit floor. It is
# invisible at rest — the "boop" flash IS the impact read. Its Polygon2D sits
# at z 5 (the map's light band, see RevolverRay/Dynamite smoke) so the flash
# renders above the DiscoShadow masks and is visible in the dark.
#
# Anything that hits it lights it up:
#   player   -> Player._on_body_entered (discowalls group)
#   dynamite -> Dynamite._on_body_entered
#   gunfire  -> RevolverRay
#   whip     -> Whiplash
# Online the host simulates every body and replays guest "use" actions, so it
# authors the flash and guests replay it (Net.disco_hit), same rule as cacti.

func boop():
	$Anim.stop(true)
	$Anim.play("boop")
	# todo: impact sfx — a hit should be heard as well as seen, probably with
	# pitch/volume per source (player / dynamite / shot / whip).
	if Net.isOnline and Net.isHost:
		Net.disco_hit(global_position)
