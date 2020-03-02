/// @description player spawner
// You can write your code in this editor
var cps = currentPlayerSpawning;
if (cps < 4) {
	if (global.player_joined[cps]) {
		var spawner = getInstanceByPlayerId(obj_player_spawner_arena, cps);
		with (instance_create_depth(spawner.x, spawner.y, -1, obj_player_arena)) {
			playerId = cps;
			hp = global.game_maxHp[global.selectedMaxHpIndex];
			sprite_index = global.player_skin[cps];
			if (getWinnerTeam() == global.player_team[playerId]) {
				for (var i = 0; i < 100; i++) {
					instance_create_depth(x, y, -2, obj_confetti);
				}
			}
		}
	}
	currentPlayerSpawning++;
	alarm[4] = room_speed / 4;
}