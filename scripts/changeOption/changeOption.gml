function changeOption(argument0) {
	audio_play_sound(snd_menu_action, 10, false);
	switch (global.selectedOption) {/*
		case 0: 
			var gameModeCnt = array_length_1d(global.game_modes);
			global.selectedModeIndex = (global.selectedModeIndex + gameModeCnt + argument0) % gameModeCnt;
			break;*/
		case 1: 
			var gameMapCnt = array_length_1d(global.game_maps);
			global.selectedMapIndex = (global.selectedMapIndex + gameMapCnt + argument0) % gameMapCnt;
			break;
		case 2: 
			var gameRoundsCnt = array_length_1d(global.game_rounds);
			global.selectedRoundsIndex = (global.selectedRoundsIndex + gameRoundsCnt + argument0) % gameRoundsCnt;
			break;
		case 3: 
			var gameMaxHpCnt = array_length_1d(global.game_maxHp);
			global.selectedMaxHpIndex = (global.selectedMaxHpIndex + gameMaxHpCnt + argument0) % gameMaxHpCnt;
			break;
	}


}
