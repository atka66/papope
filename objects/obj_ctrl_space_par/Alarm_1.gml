/// @description comet spawner
// You can write your code in this editor
instance_create_depth(irandom(room_width), irandom(room_height), 98, obj_space_comet);
alarm[1] = irandom_range(1, 100);