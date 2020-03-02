/// @description HUTS!!
// You can write your code in this editor
var collisionInst = noone;
var currentLength = 16;
var crackX = x;
var crackY = y;
while (currentLength < 96) {
	crackX = x + lengthdir_x(currentLength, direction);
	crackY = y + lengthdir_y(currentLength, direction);
	var collisionInst = collision_point(crackX, crackY, obj_player_arena, true, true);
	if (collisionInst != noone && collisionInst != originPlayer) {
		with (collisionInst) {
			hurtPlayer(self, 30);
			audio_play_sound(snd_whip_hit_1, 10, false);
			motion_add(point_direction(other.x, other.y, crackX, crackY), 15);
		}
		break;
	}
	currentLength += 8;
}
instance_create_depth(crackX, crackY, -2, obj_whipcrack);