shader_type canvas_item;

uniform float strength = 0.005;
uniform float speed = 2.0;

void fragment()
{
	vec2 coord = SCREEN_UV;
	float offset = sin(TIME * speed) * strength;
	coord.y += offset;
	COLOR = texture(SCREEN_TEXTURE, coord);
}