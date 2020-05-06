/// @description Draw controller sprites accordingly
// You can write your code in this editor
var ctrl_col = c_white;
if (gamepad_is_connected(slotId)) {
	if (global.player_joined[slotId]) {
		ctrl_col = getPlayerColor(global.player_team[slotId]);
		if (instance_find(obj_ctrl_lobby, 0).cntdwn) {
			drawSpriteText(x - 40, y + 22, "CANCEL", spr_controller_o);
		} else {
			drawSpriteText(x - 40, y + 22, "LEAVE", spr_controller_o);
		}
	} else {
		if (!instance_find(obj_ctrl_lobby, 0).cntdwn) {
			draw_sprite(spr_player_summon, 0, x, y - 32);
			drawSpriteText(x - 40, y + 22, "JOIN", spr_controller_x);
		}
	}
	draw_sprite_ext(spr_controller, 0, x, y, 1, 1, 0, ctrl_col, 1.0);
} else {
	draw_sprite_ext(spr_controller, 0, x, y, 1, 1, 0, ctrl_col, 0.3);
	drawText(x, y + 16, "OFFLINE", 1, c_white, 0.3, 1);
}