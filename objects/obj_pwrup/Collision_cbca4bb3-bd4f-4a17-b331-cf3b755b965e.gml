/// @description Insert description here
// You can write your code in this editor
if (other.alive) {
	var pwrup = pwrupName;
	with (instance_create_depth(x - 30, y - 5, -2, obj_toast_msg)) {
		aliveTime = 1 * room_speed;
		text = pwrup;
		alarm[3] = 1;
	}
	audio_play_sound(snd_pickup, 10, false);
	instance_destroy(self);
}