/// @description Insert description here
// You can write your code in this editor
audio_play_sound(snd_dynamite_explode, 10, false);
instance_create_depth(x, y, -5, obj_dynamite_explosion);
emitParticleExplosion(x, y);
for (var i = 0; i < 4; i++) {
	var playerInst = getInstanceByPlayerId(obj_player_arena, i);
	if (playerInst != noone) {
		var dist = distance_to_point(playerInst.x, playerInst.y);
		if (dist < 150) {
			var force = 150 - dist;
			with (playerInst) {
				motion_add(point_direction(other.x, other.y, x, y), force / 10);
			}
			hurtPlayer(playerInst, force / 1.5);
		}
	}
}