/// @description Insert description here
// You can write your code in this editor
if (gamepad_button_check_pressed(pausingPlayerId, gp_face2)) {
	instance_destroy(self)
}

if (gamepad_button_check_pressed(pausingPlayerId, gp_face3)) {
	for (var i = 0; i < 4; i++) {
		global.player_points[i] = 0;
	}
	determineMap();
}

if (gamepad_button_check_pressed(pausingPlayerId, gp_face4)) {
	room_goto(r_lobby)
}