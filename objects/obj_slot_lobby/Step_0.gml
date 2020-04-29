/// @description Handle controller input
// You can write your code in this editor
// 'x' pressed
if (gamepad_button_check_pressed(slotId, gp_face1)) {
	if (!lobbyPlayerInstanceExists(slotId)) {
		createPlayer(slotId);
	} else {
		if (instance_number(obj_player_lobby) < 2) {
			warningGrowl("NEEDS AT LEAST 2 PLAYERS!");
		} else if (getNumberOfTeams() < 2) {
			warningGrowl("NEEDS AT LEAST 2 TEAMS!");
		} else {
			startCntdwn();
		}
	}
}

// 'o' pressed
if (gamepad_button_check_pressed(slotId, gp_face2) && lobbyPlayerInstanceExists(slotId)) {
	if (instance_find(obj_ctrl_lobby, 0).cntdwn) {
		stopCntdwn();
	} else {
		global.player_crowned[slotId] = false;
		instance_destroy(getInstanceByPlayerId(obj_player_lobby, slotId));
	}
}

// disconnect
if (!gamepad_is_connected(slotId) && lobbyPlayerInstanceExists(slotId)) {
	instance_destroy(getInstanceByPlayerId(obj_player_lobby, slotId))
}
