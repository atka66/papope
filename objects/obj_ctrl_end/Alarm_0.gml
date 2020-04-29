/// @description Insert description here
// You can write your code in this editor
for (var i = 0; i < 40; i++) {
	with (instance_create_depth(0, room_height, -3, obj_confetti)) {
		direction = irandom_range(50, 80);
	}
}
for (var i = 0; i < 40; i++) {
	with (instance_create_depth(room_width - 1, room_height, -3, obj_confetti)) {
		direction = irandom_range(130, 100);
	}
}

alarm[0] = 3 * room_speed;