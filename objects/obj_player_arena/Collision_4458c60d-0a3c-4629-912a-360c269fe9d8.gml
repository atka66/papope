/// @description Insert description here
// You can write your code in this editor
if (fallWater == false) {
	audio_play_sound(snd_player_slipinwater, 10, false)
	fallWater = true;
	alarm[1] = 30;
	hspeed = 7 * (x < room_width / 2 ? -1 : 1);
	vspeed = -5;
	gravity = 1;
}