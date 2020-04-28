/// @arg x
/// @arg y
/// @arg col
/// @arg dir
/// @arg speed
/// @arg ttl
/// @arg maxSize
with (instance_create_depth(argument0, argument1, -4, obj_par_circle)) {
	color = argument2;
	direction = argument3;
	speed = argument4;
	image_index = irandom_range(0, argument6);
	
	alarm[0] = argument5;
	fade = 1.0 / argument5;
}