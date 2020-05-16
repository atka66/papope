/// @description Insert description here
// You can write your code in this editor
if (speed > 0) {
	image_angle += 15;
}
emitParticleSpark(x + (dcos(image_angle) * 10), y - (dsin(image_angle) * 10), c_yellow);