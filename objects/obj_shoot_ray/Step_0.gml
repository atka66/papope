/// @description Insert description here
// You can write your code in this editor
if (firstStep) {
	firstStep = false;
	var it = 0;
	var collidingObj = noone;
	while (it < 10000) {
		it++;
		endX = x + (deltaX * it);
		endY = y + (deltaY * it);
		// colliding with player
		collidingObj = collision_point(endX, endY, obj_player_arena, true, true);
		if (collidingObj != noone && collidingObj != getInstanceByPlayerId(obj_player_arena, originPlayer)) {
			audio_play_sound(snd_player_shot, 10, false);
			with (collidingObj) {
				motion_add(point_direction(other.x, other.y, x, y), 3);
			}
			emitParticleCollide(endX, endY, c_red);
			hurtPlayer(collidingObj, 20);
			break;
		}
		// colliding with cactus
		if (collision_point(endX, endY, obj_cactus, true, true) != noone) {
			audio_play_sound(snd_cactus_shot, 10, false);
			emitParticleCollide(endX, endY, c_yellow);
			break;
		}
		// colliding with wood
		if (
			collision_point(endX, endY, obj_mast, true, true) != noone ||
			collision_point(endX, endY, obj_tree, true, true) != noone
		) {
			audio_play_sound(choose(snd_collide_wood_1, snd_collide_wood_2, snd_collide_wood_3), 10, false);
			emitParticleCollide(endX, endY, c_orange);
			break;
		}
		// colliding with metal
		if (collision_point(endX, endY, obj_car, true, true) != noone) {
			audio_play_sound(choose(snd_collide_metal_1, snd_collide_metal_2, snd_collide_metal_3), 10, false);
			emitParticleCollide(endX, endY, c_yellow);
			break;
		}
	}
}
alpha -= 0.3
if (alpha <= 0) {
	instance_destroy(self)
}