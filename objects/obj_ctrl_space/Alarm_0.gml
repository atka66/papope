/// @description star spawner
// You can write your code in this editor
instance_create_layer(irandom(room_width), irandom(room_height), "Stars", obj_space_star);
alarm[0] = 1;