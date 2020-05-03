/// @description show hint
// You can write your code in this editor
var hint = choose(
	createArray("DEATH MAKES YOU DIE"),
	createArray("BE CAREFUL NOT TO", "FALL OFF THE SHIP"),
	createArray("TRAPS STUN FOR 2 SECONDS"),
	createArray("STAYING OUT OF BOUNDS", "FOR TOO LONG WILL KILL YOU"),
	createArray("SHIELD DOES NOT SAVE YOU", "FROM FALLING OFF SHIPS", "OR STAYING OUT FOR LONG"),
	createArray("DYNAMITES TEND TO BOUNCE", "BACK FROM A LOT OF THINGS"),
	createArray("YOU CAN AVOID REVOLVER", "SHOTS BY HIDING BEHIND", "CERTAIN OBJECTS"),
	createArray("PICKING UP A POWERUP", "REPLACES THE CURRENTLY", "EQUIPPED ONE"),
	createArray("YOU CANNOT MOVE IN SPACE", "BUT YOU CAN DASH")
);

var timer = hintTimer;
for (var i = 0; i < array_length_1d(hint); i++) {
	with (instance_create_depth(510, 128 + (i * 16), 101, obj_toast_msg)) {
		aliveTime = timer * room_speed;
		text = hint[i];
		align = 1;
		alarm[3] = 1;
	}
}
alarm[1] = timer * room_speed;