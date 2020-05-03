/// @description Draw controller sprites accordingly
// You can write your code in this editor
var ctrl_col = c_white;
if (gamepad_is_connected(slotId)) {
	var joined = lobbyPlayerInstanceExists(slotId)
	if (joined) {
		ctrl_col = getPlayerColor(global.player_team[slotId]);
	}
	draw_sprite_ext(spr_controller, 0, x, y, 1, 1, 0, ctrl_col, 1.0);

	if (joined) {
		if (instance_find(obj_ctrl_lobby, 0).cntdwn) {
			drawSpriteText(x - 40, y + 20, spr_controller_o, "CANCEL")
		} else {
			drawSpriteText(x - 40, y + 20, spr_controller_x, "START")
			drawSpriteText(x - 40, y + 40, spr_controller_o, "LEAVE")
		}
	} else {
		if (!instance_find(obj_ctrl_lobby, 0).cntdwn) {
			draw_sprite(spr_player_summon, 0, x, y - 32);
			drawSpriteText(x - 40, y + 20, spr_controller_x, "JOIN")
		}
	}
} else {
	draw_sprite_ext(spr_controller, 0, x, y, 1, 1, 0, ctrl_col, 0.3);
	drawText(x, y + 20, "OFFLINE", 2, c_white, 0.3, 1);
}