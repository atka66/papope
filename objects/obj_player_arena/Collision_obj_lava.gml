/// @description Insert description here
// You can write your code in this editor
if (contactedLava == false) {
	audio_play_sound(snd_player_contact_lava, 10, false)
	contactedLava = true;
}
emitParticleSmoke(irandom_range(x - 4, x + 4), y + 14);
hurtByLava = true;