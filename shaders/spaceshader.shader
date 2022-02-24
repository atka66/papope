shader_type canvas_item;

uniform sampler2D noise;
uniform float r = 1.0;
uniform float b = 1.0;

void fragment()
{
	vec2 coord = UV;
	coord.x += TIME * -0.005;
	float val = texture(noise, coord).r - 0.5;
	COLOR = vec4(r * val, 0.0, b * val, 1.0);
}