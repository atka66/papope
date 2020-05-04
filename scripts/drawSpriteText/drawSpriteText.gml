var spriteCnt = argument_count - 3;

for (var i = 3; i < argument_count; i++) {
	draw_sprite(argument[i], current_second % 2, argument[0] + 8 + ((i - 3) * 20), argument[1] + 5);
}
drawText(argument[0] + (20 * spriteCnt), argument[1], argument[2], 2, c_white, 1.0, 0);