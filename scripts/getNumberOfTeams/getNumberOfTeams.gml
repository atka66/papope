var teamList = ds_list_create();
for (var i = 0; i < 4; i++) {
	if (global.player_joined[i] && ds_list_find_index(teamList, global.player_team[i]) == -1) {
		ds_list_add(teamList, global.player_team[i]);
	}
}
return ds_list_size(teamList);