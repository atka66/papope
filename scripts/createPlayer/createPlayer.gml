var player = instance_create_depth(x, y - 32, 0, obj_player_lobby);
with (player) {
	playerId = argument0;
	global.player_joined[playerId] = true;
	sprite_index = global.player_skin[playerId];
}