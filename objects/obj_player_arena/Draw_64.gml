/// @description Insert description here
// You can write your code in this editor
if (alive) {
	if (item == obj_pwrup_revolver) {
		var rhValue = gamepad_axis_value(playerId, gp_axisrh);
		var rvValue = gamepad_axis_value(playerId, gp_axisrv);
		var length = point_distance(0, 0, rhValue, rvValue) * 200;
		var angle = darctan2(-rvValue, rhValue);
		draw_sprite_ext(spr_crosshair, 0, x + lengthdir_x(length, angle), y + lengthdir_y(length, angle), 1, 1, angle, merge_color(getPlayerColor(global.player_team[playerId]), c_white, 0.5), 0.7);
	}
	if (item == obj_pwrup_dynamite) {
		var rhValue = gamepad_axis_value(playerId, gp_axisrh);
		var rvValue = gamepad_axis_value(playerId, gp_axisrv);
		var length = point_distance(0, 0, rhValue, rvValue) * 200;
		var angle = darctan2(-rvValue, rhValue);
		draw_sprite_ext(spr_crosshair, 1, x + lengthdir_x(length, angle), y + lengthdir_y(length, angle), 1, 1, angle, merge_color(getPlayerColor(global.player_team[playerId]), c_white, 0.5), 0.7);
	}
	if (item == obj_pwrup_whip) {
		var rhValue = gamepad_axis_value(playerId, gp_axisrh);
		var rvValue = gamepad_axis_value(playerId, gp_axisrv);
		var length = point_distance(0, 0, rhValue, rvValue) * 96;
		var angle = darctan2(-rvValue, rhValue);
		draw_sprite_ext(spr_crosshair, 2, x + lengthdir_x(length, angle), y + lengthdir_y(length, angle), 1, 1, angle, merge_color(getPlayerColor(global.player_team[playerId]), c_white, 0.5), 0.7);
	}
	
	if (isOutsideView() && outsideCntdwn > 0) {
		drawText(max(min(x, room_width - 32), 32), max(min(y, room_height - 32), 32), string(ceil(outsideCntdwn / 60)), 2, current_time mod 8 < 4 ? c_white : c_red, 1.0, 0, true);
	}
}