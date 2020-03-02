/// @description Insert description here
// You can write your code in this editor
motion_add(other.direction, other.speed + 5);
motion_add(y < other.y ? 90 : -90, 10);
hurtPlayer(self, 20);
emitParticles(x, y, c_white, 10);
audio_play_sound(choose(snd_collide_car_1, snd_collide_car_2, snd_collide_car_3), 10, false);