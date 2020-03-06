/// @description spawn powerup
// You can write your code in this editor
instance_destroy(instance_find(obj_pwrup, 0));

var randX;
var randY;
do {
	randX = irandom_range(32, room_width - 32);
	randY = irandom_range(32, room_height - 32);
} until (
	!(instance_position(randX, randY, obj_player_arena) ||
	instance_position(randX, randY, obj_lava) ||
	instance_position(randX, randY, obj_cactus) ||
	instance_position(randX, randY, obj_block) ||
	instance_position(randX, randY, obj_cannon) ||
	instance_position(randX, randY, obj_mast) ||
	instance_position(randX, randY, obj_tree) ||
	instance_position(randX, randY, obj_fallwater))
)

instance_create_depth(randX, randY, -1, choose(
	obj_pwrup_dynamite, 
	obj_pwrup_revolver, 
	obj_pwrup_shield, 
	obj_pwrup_whip, 
	obj_pwrup_trap
));
alarm[2] = room_speed * 6;