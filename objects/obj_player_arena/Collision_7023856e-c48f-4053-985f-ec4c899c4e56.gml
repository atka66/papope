/// @description Insert description here
// You can write your code in this editor
if (other.sprite_index != spr_spaceray_phase_1) {
	hspeed = x < room_width / 2 ? -10 : 10;
	hurtPlayer(self, 25);
	audio_play_sound(choose(snd_spaceray_hit_1, snd_spaceray_hit_2), 10, false);
}