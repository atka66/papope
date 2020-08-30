/// @description Insert description here
// You can write your code in this editor

if (!hit) {
	other.hit = true;

	var selfSpeed = sqrt(sqr(hspeed) + sqr(vspeed));
	var otherSpeed = sqrt(sqr(other.hspeed) + sqr(other.vspeed));
	var new_angle = point_direction(x, y, other.x, other.y);

	hspeed = -dcos(new_angle) * otherSpeed;
	vspeed = dsin(new_angle) * otherSpeed;
	other.hspeed = dcos(new_angle) * selfSpeed;
	other.vspeed = -dsin(new_angle) * selfSpeed;
	
	speed += 1;
	other.speed += 1;
	
	audio_play_sound(choose(snd_player_col_player_1, snd_player_col_player_2, snd_player_col_player_3), 10, false);
	var xDiff = other.x - x;
	var yDiff = other.y - y;
	var scale = (speed + other.speed) / 7;
	with (instance_create_depth(x + (xDiff / 2), y + (yDiff / 2), -5, obj_anim_playercollide)) {
		image_angle = darctan2(-yDiff, xDiff);
		image_xscale = scale;
		image_yscale = scale;
	}
}
hit = false;