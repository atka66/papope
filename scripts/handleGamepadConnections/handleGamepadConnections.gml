function handleGamepadConnections() {
	var slotId = async_load[?"pad_index"];
	if (slotId < 4) {
		switch(async_load[?"event_type"]) {
			case "gamepad lost":
				global.player_connected[slotId] = false;
				warningGrowl("GAMEPAD SLOT #" + string(slotId + 1) + " LOST");
				break;
			case "gamepad discovered":
				global.player_connected[slotId] = true;
				warningGrowl("GAMEPAD SLOT #" + string(slotId + 1) + " CONNECTED");
				break;
		}
	}


}
