/// @description Insert description here
// You can write your code in this editor
if (!firstStep) {
	var alp = draw_get_alpha();
	draw_set_alpha(alpha);
	draw_line_color(x, y, endX, endY, c_white, c_white);
	draw_set_alpha(alp);
	draw_sprite_ext(spr_muzzle_flash, 0, x, y, 1, 1, darctan2(-deltaY, deltaX), c_white, 1.0);
}