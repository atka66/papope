/// @description Insert description here
// You can write your code in this editor
if (other.armed) {
	with (other) {
		armed = false;
		image_index = 1;
		image_alpha = 1.0;
		motion_add(irandom(360), 3);
		alarm[1] = room_speed * 2;
	}
	emitParticles(x, y, c_yellow, 10);
	// todo rename whip or replace sound
	audio_play_sound(choose(snd_whip_huts_1, snd_whip_huts_2, snd_whip_huts_3), 10, false);
	hurtPlayer(self, 35);
	motion_add(irandom(360), 10);
}