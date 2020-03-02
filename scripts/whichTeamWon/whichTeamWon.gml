var teamList = ds_list_create();
for (var i = 0; i < 4; i++) {
	if (
		global.player_joined[i] &&
		ds_list_find_index(teamList, global.player_team[i]) == -1 &&
		getInstanceByPlayerId(obj_player_arena, i).hp > 0
	) {
		ds_list_add(teamList, global.player_team[i]);
	}
}
switch (ds_list_size(teamList)) {
	// no one is alive, draw (rare)
	case 0: return -2;
	// if only one alive, return the ID of the player
	case 1: return teamList[|0];
	// more than one are alive, return -1
	default: return -1;
}