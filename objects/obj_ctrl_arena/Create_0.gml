/// @description Insert description here
// You can write your code in this editor
// create and freeze players
global.playersFrozen = true;
alarm[4] = room_speed / 2;

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
			with (instance_create_depth(hudX, hudY, -3, obj_hud)) {
				playerId = i;
				alarm[0] = 1 * room_speed;
			}
		}
	}
}

if (winnerTeam < 0) {
	// splash text
	var delay = 1;
	with (instance_create_depth(room_width / 2, 40, -2, obj_toast_msg)) {
		aliveTime = 2 * room_speed;
		text = "GET READY!";
		align = 1;
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_init;
	}
	with (instance_create_depth(room_width / 2, 40, -2, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = "3";
		align = 1;
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_toast;
	}
	with (instance_create_depth(room_width / 2, 40, -2, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = "2";
		align = 1;
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_toast;
	}
	with (instance_create_depth(room_width / 2, 40, -2, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = "1";
		align = 1;
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_toast;
	}
	with (instance_create_depth(room_width / 2, 40, -2, obj_toast_go)) {
		aliveTime = 1 * room_speed;
		text = "GO!";
		align = 1;
		alarm[3] = delay;
	}
	// powerup init
	alarm[2] = room_speed * 10;
} else {
	// WE HAVE A WINNER WOO HOO
	with (instance_create_depth(room_width / 2, 40, -2, obj_toast_msg)) {
		aliveTime = 5 * room_speed;
		text = getPlayerColorString(winnerTeam) + " WON THE GAME";
		align = 1;
		alarm[3] = 1;
		initSound = snd_winner;
	}
	alarm[1] = 5 * room_speed;
}