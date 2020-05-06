/// @description Insert description here
// You can write your code in this editor
// pad
if (!cntdwn) {
	if (keyboard_check_pressed(vk_left)) {
		changeOption(-1);
	}

	if (keyboard_check_pressed(vk_right)) {
		changeOption(1);
	}

	if (keyboard_check_pressed(vk_up)) {
		switchOption(1);
	}

	if (keyboard_check_pressed(vk_down)) {
		switchOption(0);
	}
}