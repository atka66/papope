function isAnyoneConnected() {
	for (var i = 0; i < 4; i++) {
		if (global.player_joined[i] && global.player_connected[i]) {
			return true;
		}
	}
	return false;


}
