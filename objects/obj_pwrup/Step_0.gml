/// @description Insert description here
// You can write your code in this editor
curvePosition += curveSpeed;
curvePosition = curvePosition mod 1;
floatHeight = animcurve_channel_evaluate(animcurve_get_channel(animcurve_get(curveAsset), "y"), curvePosition)