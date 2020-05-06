/// @description Insert description here
// You can write your code in this editor
if (!global.prefs_DisconnectOnInit) {
	if (global.player_joined[slotId]) {
		createPlayer(slotId);
	}
} else {
	global.player_joined[slotId] = false;
}