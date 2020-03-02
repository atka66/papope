for (var i = 0; i < instance_number(argument0); i++) {
	var playerInstanceId = instance_find(argument0, i);
	if (playerInstanceId.playerId == argument1) {
		return playerInstanceId;
	}
}
return noone;