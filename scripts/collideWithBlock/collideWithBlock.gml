function collideWithBlock() {
	move_bounce_solid(true);
	if (speed > 5) {
		audio_play_sound(choose(snd_collide_block_1, snd_collide_block_2, snd_collide_block_3), 10, false);
	}


}
