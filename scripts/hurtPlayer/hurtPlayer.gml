function hurtPlayer(argument0, argument1) {
	with (argument0) {
		if (argument1 > 0 && alive && !invulnerable && !global.playersFrozen) {
			hp -= argument1;
			var pid = playerId;
			with (instance_create_depth(x, y, 103, obj_par_hpremove)) {
				playerId = pid;
				damage = ceil(argument1);
			}
			shakeHud(pid, ceil(argument1 / 5));
			hurtIntensity = 1.0;
		}
	}


}
