/// @description car spawner
// You can write your code in this editor
var carSpeed = irandom_range(5, 7);
var carAlive = (room_width + 200) / carSpeed;
var right = goesRight;
with (instance_create_depth(right ? -64 : room_width + 64, y, -2, obj_car)) {
	image_xscale = right ? -1 : 1;
	hspeed = right ? carSpeed : -carSpeed;
	alarm[0] = carAlive;
	image_index = irandom_range(1, 5);
}
alarm[0] = carAlive + irandom(200);