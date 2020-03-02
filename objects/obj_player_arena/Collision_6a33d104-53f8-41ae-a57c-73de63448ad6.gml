/// @description Insert description here
// You can write your code in this editor
if (contactedLava == false) {
	audio_play_sound(snd_player_contact_lava, 10, false)
	contactedLava = true;
}
instance_create_depth(irandom_range(x - 6, x + 6), y + 14, -2, obj_par_smoke);
hurtByLava = true;