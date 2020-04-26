/// @description Insert description here
// You can write your code in this editor
move_bounce_all(true);
motion_add(point_direction(other.x, other.y, x, y), 2);

emitParticleCollide(x, y, c_yellow);
audio_play_sound(snd_player_col_cactus, 10, false);
hurtPlayer(self, 10);