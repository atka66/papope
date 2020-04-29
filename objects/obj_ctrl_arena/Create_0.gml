/// @description Insert description here
// You can write your code in this editor
// create and freeze players
global.playersFrozen = true;
alarm[4] = room_speed * 2;

var winnerTeam = getWinnerTeam();
for (var i = 0; i < 4; i++) {
	if (global.player_joined[i]) {
		// hud
		var hudX = 0;
		var hudY = 0;
		switch (i) {
			case 0: hudX = -152; hudY = 4; break;
			case 1: hudX = 720; hudY = 4;  break;
			case 2: hudX = -152; hudY = 340; break;
			case 3: hudX = 720; hudY = 340; break;
		}
		if (winnerTeam < 0) {
			with (instance_create_depth(hudX, hudY, 102, obj_hud)) {
				playerId = i;
				alarm[0] = 2.5 * room_speed;
			}
		}
	}
}

if (winnerTeam < 0) {
	// map name
	with (instance_create_depth(64, room_height - 96, 101, obj_toast_msg)) {
		aliveTime = 2 * room_speed;
		text = global.game_maps[global.actualSelectedMapIndex];
		textSize = 6;
		align = 0;
		alarm[3] = 1;
		initSound = snd_game_init;
	}
	// fade in alarm
	alarm[3] = 0.5 * room_speed;
	// splash text
	var delay = 1 * room_speed;
	with (instance_create_depth(room_width / 2, 40, 101, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = "3";
		align = 1;
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_toast;
	}
	with (instance_create_depth(room_width / 2, 40, 101, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = "2";
		align = 1;
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_toast;
	}
	with (instance_create_depth(room_width / 2, 40, 101, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = "1";
		align = 1;
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_toast;
	}
	with (instance_create_depth(room_width / 2, 40, 101, obj_toast_go)) {
		aliveTime = 1 * room_speed;
		text = "GO!";
		align = 1;
		alarm[3] = delay;
	}
	// powerup init
	alarm[2] = room_speed * 10;
} else {
	// WE HAVE A WINNER WOO HOO
	room_goto(r_end);
}