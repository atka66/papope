/// @description Insert description here
// You can write your code in this editor
if (appearing) {
	if (dim > -3) {
		dim -= 0.02;
	} else {
		appearing = false;
	}
} else {
	if (dim < 1) {
		dim += 0.02;
	} else {
		event_user(0);
	} 
}
layer_background_alpha(layer_background_get_id("dim"), dim);