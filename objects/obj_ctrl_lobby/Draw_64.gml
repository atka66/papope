/// @description Insert description here
// You can write your code in this editor
drawText(room_width - 128, 16, "PAPOPE", 5, c_white, 1.0, 1);
drawText(room_width - 128, 48, "A GAME BY ATKA", 2, c_white, 0.5, 1);
drawText(0, room_height - 16, "V" + string(GM_version), 2, c_white, 0.5, 0);
drawText(room_width, room_height - 16, "atka66.itch.io/papope", 2, c_white, 0.5, 2);

drawText(510, 112, "HINT:", 2, c_white, 1.0, 1);

if (instance_number(obj_player_lobby) > 0) {
	var cntdwn = instance_find(obj_ctrl_lobby, 0).cntdwn;
	drawText(5, 5, "MENU CTRL:", 2, c_white, 1.0, 0);
	drawSpriteText(5, 25, "CHANGE SKIN", spr_controller_l1, spr_controller_r1)
	drawSpriteText(5, 45, "CHANGE TEAM", spr_controller_l2, spr_controller_r2)
	if (global.prefs_AllowPlayersSetOptions) {
		drawSpriteText(5, 65, "NAVIGATION", spr_controller_pad);
	}
	drawText(250, 5, "IN-GAME CTRL:", 2, c_white, 1.0, 0);
	drawSpriteText(250, 25, "MOVEMENT", spr_controller_sl);
	drawSpriteText(250, 45, "AIM", spr_controller_sr);
	drawSpriteText(250, 65, "DASH", spr_controller_l1);
	drawSpriteText(250, 85, "USE", spr_controller_r1);
	
	// TODO modes
	/*drawText(166, 127, "MODE:", 2, c_white, 1.0, 2);
	drawText(186, 127, global.game_modes[global.selectedModeIndex], 2, c_white, 1.0, 0);*/
	
	drawText(166, 152, "MAP:", 2, c_white, 1.0, 2);
	drawText(186, 152, global.game_maps[global.selectedMapIndex], 2, c_white, 1.0, 0);
	
	drawText(166, 177, "ROUNDS:", 2, c_white, 1.0, 2);
	drawText(186, 177, global.game_rounds[global.selectedRoundsIndex], 2, c_white, 1.0, 0);
	
	drawText(166, 202, "HP:", 2, c_white, 1.0, 2);
	drawText(186, 202, global.game_maxHp[global.selectedMaxHpIndex], 2, c_white, 1.0, 0);
	
	for (var i = 1; i < 4; i++) {
		if (global.selectedOption == i && !cntdwn) {
			draw_sprite(spr_menu_arrow, 0, 64, 125 + (i * 25));
			draw_sprite(spr_menu_arrow, 1, 288, 125 + (i * 25));
		}
	}
}

if (instance_number(obj_player_lobby) < 2) {
	drawText(room_width / 2, room_height - 48, "WAITING FOR MORE PLAYERS...", 2, c_white, 1.0, 1);
} else if (getNumberOfTeams() < 2) {
	drawText(room_width / 2, room_height - 48, "MUST HAVE AT LEAST 2 TEAMS!", 2, c_white, 1.0, 1);
} else {
	drawSpriteText((room_width / 2) - 64, room_height - 48, "START", spr_controller_x);
}