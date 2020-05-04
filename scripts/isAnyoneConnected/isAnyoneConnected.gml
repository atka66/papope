for (var i = 0; i < 4; i++) {
	if (global.player_joined[i] && gamepad_is_connected(i)) {
		return true;
	}
}
return false;