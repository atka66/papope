/// @description Insert description here
// You can write your code in this editor
layer_background_index(layer_background_get_id("background"), irandom(sprite_get_number(bg_space) - 1));

winners = ds_list_create();
winnerTeam = getWinnerTeam();

for (var i = 0; i < 4; i++) {
	if (global.player_joined[i]) {
		if (global.player_team[i] == winnerTeam) {
			global.player_crowned[i] = true;
			ds_list_add(winners, i);
		} else {
			global.player_crowned[i] = false;
		}
	}
}

for (var i = 0; i < ds_list_size(winners); i++) {
	var winner = winners[|i];
	with (instance_create_depth((room_width / 2) + (i * 128 - ((ds_list_size(winners) - 1) * 64)), room_height / 2, 0, obj_crown_end)) {
		playerId = winner;
		sprite_index = global.player_skin[i];
	}
}

audio_play_sound(snd_winner, 10, false);

alarm[0] = 1;