/// @description Insert description here
// You can write your code in this editor
var color = (alive ? (invulnerable ? c_yellow : getPlayerColor(global.player_team[playerId])) : c_dkgray);

draw_sprite_ext(spr_player_circle, 0, x, y, 1.0, 1.0, 0, color, 1.0);

draw_sprite(spr_skins, sprite_index, x, y);
if (invulnerable) {
	drawText(x - 4, y - 4, string(ceil(alarm_get(0) / 60)), 2, c_white, 1.0, 0, true);
}
if (trapped) {
	drawText(x - 4, y - 4, string(ceil(alarm_get(2) / 60)), 2, c_gray, 1.0, 0, true);
}
if (global.player_crowned[playerId]) {
	draw_sprite(spr_player_crown, 0, x, y - 18);
}