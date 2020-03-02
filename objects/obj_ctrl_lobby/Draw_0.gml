/// @description Insert description here
// You can write your code in this editor
drawText(0, room_height - 16, "V" + string(GM_version), 2, c_white, 1.0);

if (instance_number(obj_player_lobby) > 0) {
	var cntdwn = instance_find(obj_ctrl_lobby, 0).cntdwn;
	drawSpriteText(5, 5, spr_controller_pad, "MENU NAV")
	drawSpriteText(5, 25, spr_controller_l1, "PREV SKIN")
	drawSpriteText(5, 45, spr_controller_r1, "NEXT SKIN")
	drawSpriteText(5, 65, spr_controller_l2, "PREV TEAM")
	drawSpriteText(5, 85, spr_controller_r2, "NEXT TEAM")
	
	drawText(150, 117, "MODE:", 2, c_white, 1.0);
	drawText(250, 117, global.game_modes[global.selectedModeIndex], 2, c_white, 1.0);
	if (global.selectedOption == 0 && !cntdwn) {
		draw_sprite(spr_menu_arrow, 0, 120, 115);
		draw_sprite(spr_menu_arrow, 1, 380, 115);
	}
	
	drawText(150, 142, "MAP:", 2, c_white, 1.0);
	drawText(250, 142, global.game_maps[global.selectedMapIndex], 2, c_white, 1.0);
	if (global.selectedOption == 1 && !cntdwn) {
		draw_sprite(spr_menu_arrow, 0, 120, 140);
		draw_sprite(spr_menu_arrow, 1, 380, 140);
	}
	
	drawText(150, 167, "ROUNDS:", 2, c_white, 1.0);
	drawText(250, 167, global.game_rounds[global.selectedRoundsIndex], 2, c_white, 1.0);
	if (global.selectedOption == 2 && !cntdwn) {
		draw_sprite(spr_menu_arrow, 0, 120, 165);
		draw_sprite(spr_menu_arrow, 1, 380, 165);
	}
	
	drawText(150, 192, "HP:", 2, c_white, 1.0);
	drawText(250, 192, global.game_maxHp[global.selectedMaxHpIndex], 2, c_white, 1.0);
	if (global.selectedOption == 3 && !cntdwn) {
		draw_sprite(spr_menu_arrow, 0, 120, 190);
		draw_sprite(spr_menu_arrow, 1, 380, 190);
	}
}