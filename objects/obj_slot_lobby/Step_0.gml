/// @description Handle controller input
// You can write your code in this editor
// 'x' pressed
if (gamepad_button_check_pressed(slotId, gp_face1) && !instance_find(obj_ctrl_lobby, 0).cntdwn) {
	if (!global.player_joined[slotId]) {
		createPlayer(slotId);
	} else {
		/*
		if (instance_number(obj_player_lobby) < 2) {
			warningGrowl("NEEDS AT LEAST 2 PLAYERS!");
		} else if (getNumberOfTeams() < 2) {
			warningGrowl("NEEDS AT LEAST 2 TEAMS!");
		} else {*/
			startCntdwn();
		//}
	}
}