/// @description Insert description here
// You can write your code in this editor
for (var i = 0; i < 4; i++) {
	if (gamepad_button_check_pressed(i, gp_face1)) {
		room_goto(r_lobby);
	}
}