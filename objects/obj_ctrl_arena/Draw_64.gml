/// @description Insert description here
// You can write your code in this editor
var baseAlpha = draw_get_alpha();
draw_set_alpha(dim);
draw_rectangle_color(0, 0, room_width, room_height, c_black, c_black, c_black, c_black, false);
draw_set_alpha(baseAlpha);