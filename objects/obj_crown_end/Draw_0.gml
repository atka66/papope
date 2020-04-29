/// @description Insert description here
// You can write your code in this editor
if (global.player_crowned[playerId]) {
	draw_sprite_ext(spr_player_crown, 0, x, y, 8, 8, 0, c_white, 1.0);
}
var color = getPlayerColor(global.player_team[playerId]);
draw_rectangle_color(x - 16, y - 8, x + 16, y + 24,
		color, color, color, color, false);
draw_sprite(spr_faces, sprite_index, x - 16, y - 8);
