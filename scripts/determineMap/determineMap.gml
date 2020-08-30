function determineMap() {
	var selectedMapIndex;
	if (global.selectedMapIndex == 0) {
		selectedMapIndex = irandom_range(1, array_length_1d(global.game_maps) - 1);
	} else {
		selectedMapIndex = global.selectedMapIndex;
	}

	global.actualSelectedMapIndex = selectedMapIndex;
	switch (global.game_maps[global.actualSelectedMapIndex]) {
		case "LAVA": room_goto(r_map_lava); break;
		case "WESTERN": room_goto(r_map_western); break;
		case "SHIP": room_goto(r_map_ship); break;
		case "SPACE": room_goto(r_map_space); break;
		case "TRAFFIC": room_goto(r_map_traffic); break;
	}


}
