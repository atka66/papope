/// @description Insert description here
// You can write your code in this editor
var rand = random(room_width + room_height)
if (rand < room_width) {
	instance_create_depth(rand, 0, -5, obj_par_lava_1);
} else {
	instance_create_depth(0, rand - room_width, -5, obj_par_lava_1);
}
alarm[0] = 3;