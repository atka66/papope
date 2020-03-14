/// @description Insert description here
// You can write your code in this editor
var rand = random(room_width + room_height)
if (rand < room_width) {
	instance_create_depth(rand, 0, -3, obj_tumbleweed);
} else {
	instance_create_depth(0, rand - room_width, -3, obj_tumbleweed);
}
alarm[0] = random_range(3, 7) * room_speed;