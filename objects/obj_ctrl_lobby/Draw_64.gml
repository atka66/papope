/// @description Insert description here
// You can write your code in this editor
drawText(room_width - 128, 16, "PAPOPE", 5, c_white, 1.0, 1, false);
drawText(room_width - 128, 48, "A GAME BY ATKA", 2, c_white, 0.5, 1, false);
drawText(0, room_height - 16, "V" + string(GM_version), 2, c_white, 0.5, 0, false);
drawText(room_width, room_height - 16, "atka66.itch.io/papope", 2, c_white, 0.5, 2, false);

drawText(510, 112, "HINT:", 2, c_white, 1.0, 1, false);

if (instance_number(obj_player_lobby) > 0) {
	var cntdwn = instance_find(obj_ctrl_lobby, 0).cntdwn;
	drawText(5, 5, "MENU CTRL:", 2, c_white, 1.0, 0, false);
	drawSpriteText(5, 25, "CHANGE SKIN", false, spr_controller_l1, spr_controller_r1)
	drawSpriteText(5, 45, "CHANGE TEAM", false, spr_controller_l2, spr_controller_r2)
	if (global.prefs_AllowPlayersSetOptions) {
		drawSpriteText(5, 65, "NAVIGATION", false, spr_controller_pad);
	}
	drawText(250, 5, "IN-GAME CTRL:", 2, c_white, 1.0, 0, false);
	drawSpriteText(250, 25, "MOVEMENT", false, spr_controller_sl);
	drawSpriteText(250, 45, "AIM", false, spr_controller_sr);
	drawSpriteText(250, 65, "DASH", false, spr_controller_l1);
	drawSpriteText(250, 85, "USE", false, spr_controller_r1);
	
	// TODO modes
	/*drawText(166, 127, "MODE:", 2, c_white, 1.0, 2, false);
	drawText(186, 127, global.game_modes[global.selectedModeIndex], 2, c_white, 1.0, 0, false);*/
	
	drawText(166, 152, "MAP:", 2, c_white, 1.0, 2, false);
	drawText(186, 152, global.game_maps[global.selectedMapIndex], 2, c_white, 1.0, 0, false);
	
	drawText(166, 177, "ROUNDS:", 2, c_white, 1.0, 2, false);
	drawText(186, 177, global.game_rounds[global.selectedRoundsIndex], 2, c_white, 1.0, 0, false);
	
	drawText(166, 202, "HP:", 2, c_white, 1.0, 2, false);
	drawText(186, 202, global.game_maxHp[global.selectedMaxHpIndex], 2, c_white, 1.0, 0, false);
	
	if (global.prefs_AllowPlayersSetOptions) {
		for (var i = 1; i < 4; i++) {
			if (global.selectedOption == i && !cntdwn) {
				draw_sprite(spr_menu_arrow, 0, 64, 125 + (i * 25));
				draw_sprite(spr_menu_arrow, 1, 288, 125 + (i * 25));
			}
		}
	}
}

if (instance_number(obj_player_lobby) < 2) {
	drawText(room_width / 2, room_height - 48, "WAITING FOR MORE PLAYERS...", 2, c_white, 1.0, 1, false);
} else if (getNumberOfTeams() < 2) {
	drawText(room_width / 2, room_height - 48, "MUST HAVE AT LEAST 2 TEAMS!", 2, c_white, 1.0, 1, false);
} else {
	drawSpriteText((room_width / 2) - 64, room_height - 48, "START", false, spr_controller_x);
}