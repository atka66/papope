function handleInputMovement() {
	var lhValue = gamepad_axis_value(playerId, gp_axislh)
	var lvValue = gamepad_axis_value(playerId, gp_axislv)
	var hDiff = 0
	var vDiff = 0

	if (abs(lhValue) > 0.1 && speed < 3) {
		hDiff = (lhValue)
	}
	if (abs(lvValue) > 0.1 && speed < 3) {
		vDiff = (lvValue)
	}
	hspeed += hDiff
	vspeed += vDiff


}
