/// @description Insert description here
// You can write your code in this editor
if (shakePwr > 0) {
	shakeOffsetX = irandom_range(-shakePwr, shakePwr);
	shakeOffsetY = irandom_range(-shakePwr, shakePwr);
	shakePwr--;
	var vibration = shakePwr / 5;
	gamepad_set_vibration(playerId, vibration, vibration);
} else {
	gamepad_set_vibration(playerId, 0, 0);
}

if (hpDelay < hp) {
	hpDelay++;
}
if (hpDelay > hp) {
	hpDelay--;
}