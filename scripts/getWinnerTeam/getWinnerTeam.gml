for (var i = 0; i < 4; i++) {
	if (global.player_points[i] == global.game_rounds[global.selectedRoundsIndex]) {
		return global.player_team[i];
	}
}
return -1;