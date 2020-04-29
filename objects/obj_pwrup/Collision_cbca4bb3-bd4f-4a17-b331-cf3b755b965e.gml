/// @description Insert description here
// You can write your code in this editor
if (other.alive) {
	var pwrup = pwrupName;
	with (instance_create_depth(x, y - 5, 101, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = pwrup;
		align = 1;
		alarm[3] = 1;
	}
	if (pwrupName == "REVOLVER") {
		audio_play_sound(snd_pickup_revolver, 10, false);
	} else {
		audio_play_sound(snd_pickup, 10, false);
	}
	instance_destroy(self);
}