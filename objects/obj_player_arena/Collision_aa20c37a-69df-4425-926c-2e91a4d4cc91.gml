/// @description Insert description here
// You can write your code in this editor
speed = 0;
motion_add(other.direction, other.speed + 5);
motion_add(y < other.y ? 90 : -90, random_range(5, 10));
hurtPlayer(self, 20);
emitParticleCollide(x, y, c_yellow);
audio_play_sound(choose(snd_collide_car_1, snd_collide_car_2, snd_collide_car_3), 10, false);