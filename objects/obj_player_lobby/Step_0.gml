/// @description Handle controller input
// You can write your code in this editor
if (!global.player_connected[playerId]) {
	if (instance_find(obj_ctrl_lobby, 0).cntdwn) {
		stopCntdwn();
	}
	instance_destroy();
}

handleInputMovement()

// gamepad 'o' or keyboard 'q' pressed
if (gamepad_button_check_pressed(playerId, gp_face2) || keyboard_check_pressed(ord("Q"))) {
	if (instance_find(obj_ctrl_lobby, 0).cntdwn) {
		stopCntdwn();
	} else {
		instance_destroy();
	}
}

if (!instance_find(obj_ctrl_lobby, 0).cntdwn) {
	// shoulders
	if (gamepad_button_check_pressed(playerId, gp_shoulderl)) {
		var spriteCnt = sprite_get_number(spr_skins);
		var newSpriteIndex = (sprite_index + spriteCnt - 1) % spriteCnt;
		sprite_index = newSpriteIndex;
		global.player_skin[playerId] = newSpriteIndex;
	}

	if (gamepad_button_check_pressed(playerId, gp_shoulderr)) {
		var spriteCnt = sprite_get_number(spr_skins);
		var newSpriteIndex = (sprite_index + 1) % spriteCnt;
		sprite_index = newSpriteIndex;
		global.player_skin[playerId] = newSpriteIndex;
	}
	
	// shoulders b
	if (gamepad_button_check_pressed(playerId, gp_shoulderlb)) {
		global.player_team[playerId] = (global.player_team[playerId] + 3) % 4;
	}

	if (gamepad_button_check_pressed(playerId, gp_shoulderrb)) {
		global.player_team[playerId] = (global.player_team[playerId] + 1) % 4;
	}

	// pad
	if (gamepad_button_check_pressed(playerId, gp_padl)) {
		changeOption(-1);
	}

	if (gamepad_button_check_pressed(playerId, gp_padr)) {
		changeOption(1);
	}

	if (gamepad_button_check_pressed(playerId, gp_padu)) {
		global.selectedOption = ((global.selectedOption + 1) % 3) + 1;
	}

	if (gamepad_button_check_pressed(playerId, gp_padd)) {
		global.selectedOption = (global.selectedOption % 3) + 1;
	}
}