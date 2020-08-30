function startCntdwn() {
	var ctrlInst = instance_find(obj_ctrl_lobby, 0);
	if (!ctrlInst.cntdwn) {
		with(ctrlInst) {
			alarm[0] = room_speed * 3;
			cntdwn = true;
		}
		var delay = 1;
		with (instance_create_depth(room_width / 2, 112, 101, obj_toast_lobbycnt)) {
			aliveTime = 1 * room_speed;
			text = "3";
			align = 1;
			alarm[3] = delay;
			delay += aliveTime;
			initSound = snd_game_toast;
		}
		with (instance_create_depth(room_width / 2, 112, 101, obj_toast_lobbycnt)) {
			aliveTime = 1 * room_speed;
			text = "2";
			align = 1;
			alarm[3] = delay;
			delay += aliveTime;
			initSound = snd_game_toast;
		}
		with (instance_create_depth(room_width / 2, 112, 101, obj_toast_lobbycnt)) {
			aliveTime = 1 * room_speed;
			text = "1";
			align = 1;
			alarm[3] = delay;
			delay += aliveTime;
			initSound = snd_game_toast;
		}
	}


}
