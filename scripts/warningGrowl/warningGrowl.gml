with (instance_create_depth(room_width / 2, 200, -2, obj_toast_msg)) {
	aliveTime = 2 * room_speed;
	text = argument0;
	align = 1;
	alarm[3] = 1;
	initSound = snd_game_toast;
}