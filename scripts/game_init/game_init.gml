gml_pragma("global", "game_init()");

// game modes
global.game_modes[0] = "ARENA"

// maps
global.game_maps[0] = "RANDOM"
global.game_maps[1] = "LAVA"
global.game_maps[2] = "WESTERN"
global.game_maps[3] = "SHIP"
global.game_maps[4] = "SPACE"
global.game_maps[5] = "TRAFFIC"

// number of rounds
global.game_rounds[0] = 1
global.game_rounds[1] = 3
global.game_rounds[2] = 5
global.game_rounds[3] = 10

// max HP
global.game_maxHp[0] = 1
global.game_maxHp[1] = 50
global.game_maxHp[2] = 100
global.game_maxHp[3] = 200
global.game_maxHp[4] = 500

// selections
global.selectedOption = 0
global.selectedModeIndex = 0
global.selectedMapIndex = 1
global.selectedRoundsIndex = 1
global.selectedMaxHpIndex = 2

surface_resize(application_surface, 680, 384);

// player information
for (var i = 0; i < 4; i++) {
	global.player_joined[i] = false;
	global.player_skin[i] = 0;
	global.player_points[i] = 0;
	global.player_team[i] = i;
}