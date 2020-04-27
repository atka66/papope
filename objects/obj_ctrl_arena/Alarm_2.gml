/// @description spawn powerup
// You can write your code in this editor

var spawner = instance_find(obj_spawner_pwrup, irandom(instance_number(obj_spawner_pwrup) - 1));

if (spawner != noone) {
	var pwrup = instance_position(spawner.x, spawner.y, obj_pwrup);
	if (pwrup != noone) {
		with (pwrup) {
			instance_destroy(self);
		}
	}

	instance_create_depth(spawner.x, spawner.y, -1, choose(
		obj_pwrup_dynamite, 
		obj_pwrup_revolver, 
		obj_pwrup_shield, 
		obj_pwrup_whip, 
		obj_pwrup_trap
	));
	alarm[2] = room_speed * 6;
}