gml_pragma("global", "game_init()");

// read settings.ini
ini_open("settings.ini")
global.prefs_DisconnectOnInit = ini_read_real("Prefs", "DisconnectOnInit", 0) == 0 ? false : true;
global.prefs_AllowPlayersSetOptions = ini_read_real("Prefs", "AllowPlayersSetOptions", 1) == 0 ? false : true;
global.selectedMapIndex = ini_read_real("Prefs", "DefaultMapIndex", 0);
global.selectedRoundsIndex = ini_read_real("Prefs", "DefaultRoundsIndex", 1);
global.selectedMaxHpIndex = ini_read_real("Prefs", "DefaultMaxHpIndex", 2);
ini_close()

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

// selections
global.selectedOption = 1
global.selectedModeIndex = 0

surface_resize(application_surface, 680, 384);

// player information
for (var i = 0; i < 4; i++) {
	global.player_connected[i] = false;
	global.player_joined[i] = false;
	global.player_skin[i] = i;
	global.player_points[i] = 0;
	global.player_team[i] = i;
	global.player_crowned[i] = false;
}