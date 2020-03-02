var ctrlInst = instance_find(obj_ctrl_lobby, 0);
if (!ctrlInst.cntdwn) {
	with(ctrlInst) {
		alarm[0] = room_speed * 3;
		cntdwn = true;
	}
	var delay = 1;
	with (instance_create_depth(250, 40, -2, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = "3";
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_toast;
	}
	with (instance_create_depth(250, 40, -2, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = "2";
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_toast;
	}
	with (instance_create_depth(250, 40, -2, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = "1";
		alarm[3] = delay;
		delay += aliveTime;
		initSound = snd_game_toast;
	}
}