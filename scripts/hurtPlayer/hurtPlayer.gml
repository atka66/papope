with (argument0) {
	if (argument1 > 0 && alive && !invulnerable && !global.playersFrozen) {
		hp -= argument1;
		shakeHud(playerId, ceil(argument1 / 5));
	}
}