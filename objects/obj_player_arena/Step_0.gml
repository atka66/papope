/// @description Handle controller input
// You can write your code in this editor
if (!place_meeting(x, y, obj_lava)) {
	contactedLava = false;
}

if (gamepad_button_check_pressed(playerId, gp_start)) {
	var pauseMenu = instance_create_depth(0, 0, 101, obj_pause_menu);
	var pid = playerId;
	with (pauseMenu) {
		pausingPlayerId = pid;
	}
}

if (hurtByLava) {
	hurtPlayer(self, 1);
	hurtByLava = false;
}

if (alive) {
	if (outsideCntdwn < 1) {
		hp = 0;
	}
	if (hp < 1) {
		hp = 0;
		alive = false;
		audio_play_sound(snd_player_die, 10, false)
		var aliveTeamId = whichTeamWon();
		if (aliveTeamId != -1) {
			global.playersFrozen = true;
			if (aliveTeamId > -1) {
				for (var i = 0; i < 4; i++) {
					if (global.player_team[i] == aliveTeamId) {
						global.player_points[i]++;
					}
				}
			}
			var toastText = aliveTeamId == -2 ? "DRAW" : getPlayerColorString(aliveTeamId) + " WINS";
			with (instance_create_depth(room_width / 2, 64, 101, obj_toast_msg)) {
				aliveTime = 3 * room_speed;
				text = toastText;
				align = 1;
				alarm[3] = 1;
				initSound = noone;
			}
			with (obj_ctrl_arena) {
				alarm[0] = 3 * room_speed;
			}
		}
		shakeHud(playerId, 20);
	}
	if (!global.playersFrozen && !fallWater) {
		if (!trapped) {
			if (friction > 0) {
				handleInputMovement();
			}

			if (gamepad_button_check_pressed(playerId, gp_shoulderl)) {
				if (speed < 10) {
					motion_add(direction, 7);
					audio_play_sound(choose(snd_player_dash_1, snd_player_dash_2, snd_player_dash_3), 10, false);
				}
			}
		}
	
		if (gamepad_button_check_pressed(playerId, gp_shoulderr)) {
			shakeHudAmmo(playerId, 5);
			switch (item) {
				case obj_pwrup_revolver:
					var rhValue = gamepad_axis_value(playerId, gp_axisrh);
					var rvValue = gamepad_axis_value(playerId, gp_axisrv);
					var pid = playerId;
					with (instance_create_depth(x, y, 1, obj_shoot_ray)) {
						deltaX = rhValue;
						deltaY = rvValue;
						originPlayer = pid;
					}
					audio_play_sound(snd_revolver_shoot, 10, false);
					ammo--;
					if (ammo < 1) {
						item = pointer_null;
					}
					break;
				case obj_pwrup_dynamite: 
					var rhValue = gamepad_axis_value(playerId, gp_axisrh);
					var rvValue = gamepad_axis_value(playerId, gp_axisrv);
					var pid = playerId;
					with (instance_create_depth(x, y, 1, obj_dynamite)) {
						hspeed = rhValue * 6;
						vspeed = rvValue * 6;
						originPlayer = pid;
					}
					audio_play_sound(snd_dynamite_throw, 10, false);
					ammo--;
					if (ammo < 1) {
						item = pointer_null;
					}
					break;
				case obj_pwrup_shield:
					invulnerable = true;
					alarm[0] = 300;
					audio_play_sound(snd_invul_start, 10, false);
					ammo--;
					if (ammo < 1) {
						item = pointer_null;
					}
					break;
				case obj_pwrup_whip:
					var rhValue = gamepad_axis_value(playerId, gp_axisrh);
					var rvValue = gamepad_axis_value(playerId, gp_axisrv);
					var angle = darctan2(-rvValue, rhValue);
					with (instance_create_depth(x, y, -3, obj_whip)) {
						originPlayer = other;
						direction = angle;
						image_angle = angle;
					}
					audio_play_sound(choose(snd_whip_huts_1, snd_whip_huts_2, snd_whip_huts_3), 10, false);
					ammo--;
					if (ammo < 1) {
						item = pointer_null;
					}
					break;
				case obj_pwrup_trap:
					instance_create_depth(x, y, 1, obj_trap);
					// TODO trap placement sound
					audio_play_sound(snd_pickup, 10, false);
					ammo--;
					if (ammo < 1) {
						item = pointer_null;
					}
					break;
			}
		}
		
		if (isOutsideView()) {
			if (outsideCntdwn > 0) {
				outsideCntdwn--;
			}
		} else {
			outsideCntdwn = 180;
		}
	}
}
// SPACE map no gravity
if (room == r_map_space && x > 160 && x < 512) {
	friction = 0;
} else {
	friction = 0.5;
}