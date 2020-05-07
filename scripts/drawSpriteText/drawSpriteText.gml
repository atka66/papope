var spriteCnt = argument_count - 4;

for (var i = 4; i < argument_count; i++) {
	draw_sprite(argument[i], current_second % 2, argument[0] + 8 + ((i - 4) * 20), argument[1] + 5);
}
drawText(argument[0] + (20 * spriteCnt), argument[1], argument[2], 2, c_white, 1.0, 0, argument[3]);