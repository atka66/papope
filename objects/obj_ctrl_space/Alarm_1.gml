/// @description comet spawner
// You can write your code in this editor
instance_create_layer(irandom(room_width), irandom(room_height), "Stars", obj_par_star_2);
alarm[1] = irandom_range(1, 100);