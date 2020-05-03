/// @description Insert description here
// You can write your code in this editor
drawText(room_width - 128, 16, "PAPOPE", 5, c_white, 1.0, 1);
drawText(room_width - 128, 48, "A GAME BY ATKA", 2, c_white, 0.5, 1);
drawText(0, room_height - 16, "V" + string(GM_version), 2, c_white, 1.0, 0);

drawText(510, 112, "HINT:", 2, c_white, 1.0, 1);

if (instance_number(obj_player_lobby) > 0) {
	var cntdwn = instance_find(obj_ctrl_lobby, 0).cntdwn;
	drawSpriteText(5, 5, spr_controller_pad, "MENU NAV")
	drawSpriteText(5, 25, spr_controller_l1, "PREV SKIN")
	drawSpriteText(5, 45, spr_controller_r1, "NEXT SKIN")
	drawSpriteText(5, 65, spr_controller_l2, "PREV TEAM")
	drawSpriteText(5, 85, spr_controller_r2, "NEXT TEAM")
	
	drawText(166, 117, "MODE:", 2, c_white, 1.0, 2);
	drawText(186, 117, global.game_modes[global.selectedModeIndex], 2, c_white, 1.0, 0);
	
	drawText(166, 142, "MAP:", 2, c_white, 1.0, 2);
	drawText(186, 142, global.game_maps[global.selectedMapIndex], 2, c_white, 1.0, 0);
	
	drawText(166, 167, "ROUNDS:", 2, c_white, 1.0, 2);
	drawText(186, 167, global.game_rounds[global.selectedRoundsIndex], 2, c_white, 1.0, 0);
	
	drawText(166, 192, "HP:", 2, c_white, 1.0, 2);
	drawText(186, 192, global.game_maxHp[global.selectedMaxHpIndex], 2, c_white, 1.0, 0);
	
	for (var i = 0; i < 4; i++) {
		if (global.selectedOption == i && !cntdwn) {
			draw_sprite(spr_menu_arrow, 0, 32, 115 + (i * 25));
			draw_sprite(spr_menu_arrow, 1, 320, 115 + (i * 25));
		}
	}
}