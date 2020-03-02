for (var i = 0; i < instance_number(obj_player_lobby); i++) {
	if (instance_find(obj_player_lobby, i).playerId == argument0) {
		return true;
	}
}
return false;